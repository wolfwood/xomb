// scheduler.d 
//

module kernel.environment.scheduler;

import kernel.core.multiboot;			// GRUB multiboot
import kernel.core.elf;					// ELF code
import kernel.core.modules;				// GRUB modules

import kernel.util.queue;

// architecture dependent
import kernel.arch.interrupts;
import kernel.arch.timer;
import kernel.arch.syscall;
import kernel.arch.context;

import kernel.dev.vga;

import kernel.environment.table;		// for environment table

import kernel.core.error;				// for return values


const int MAX_ENVIRONMENTS = 1024;  // Fuck you D compiler

struct Scheduler
{

static:
	
	// the quantum length in picoseconds
	const ulong quantumInterval = 50000000000;

  	// Create the scheduler queue
  	alias circleQueue!(Environment*, MAX_ENVIRONMENTS) theQueue;
  
	// TODO: probably need one per CPU...
	Environment* curEnvironment;
  
	ErrorVal init()
	{
	  	// set up environment table
		if (EnvironmentTable.init() == ErrorVal.Fail)
		{
			return ErrorVal.Fail;
		}
		
		// Init the queue
		theQueue.init();
		kprintfln!("beat it!")();
		// add a new environment
		// Get all grub modules and load them in to the environment table
		for(int i = 0; i < GRUBModules.length; i++) 
		{

			Environment* environ;
			kprintfln!("Scheduler: Creating new environment.")();

			EnvironmentTable.newEnvironment(environ);

			// Add the environment to the scheduler's queue
			theQueue.push(environ);


			// load an executable from the multiboot header
			kprintfln!("Scheduler: Loading from GRUB module.")();

			environ.loadGRUBModule(i);
		}

		Interrupts.setCustomHandler(Interrupts.Type.DivByZero, &quantumFire);

		return ErrorVal.Success;
	}

	// called when the quantum fire
	void quantumFire(InterruptStack* stack)
	{
		// schedule!
	  	Environment* temp = theQueue.pop();
		theQueue.push(temp);
		schedule();

		//Timer.resetTimer(0, quantumInterval);
	}

	// called to schedule a new process
	void schedule()
	{
		if (curEnvironment !is null) {
			// assume that the context switching code has been
			// done in these two places:

			// isr_common()
			// syscall_dispatcher()

			curEnvironment.postamble();
		}

		// find candidate for execution

		kprintfln!("schedule(): Scheduling new environment.  Current eid: {}")(curEnvironment.id);
		


		Environment* temp = theQueue.peek();
		curEnvironment = temp;

	  	kprintfln!("schedule(): New Environment Selected.  eid: {}")(curEnvironment.id);
	
	
		// curEnvironment should be set to the next
		// environment to be executed

		// restore the stack, this should already have the 
		// RIP to return from calling schedule()

		// the resulting return should get to the context
		// switch restore code for the architecture

		//mixin(contextStackRestore!("curEnvironment.stackPtr"));
		curEnvironment.preamble();
		curEnvironment.execute();				
		
		// return
	}

	void yield()
	{
		kprintfln!("Yield from eid: {}")(curEnvironment.id);

		Environment* temp = theQueue.pop();
		theQueue.push(temp);
		schedule();



	}

	void exit()
	{
		EnvironmentTable.removeEnvironment(curEnvironment.id);
		theQueue.pop();
		curEnvironment = null;

		if (EnvironmentTable.count == 0) 
		{
			// cripes, no more environments
			// shut down!
			kprintfln!("Scheduler: No more environments.")();
			for(;;) {}
		}

		schedule();
	}

	// called at the first run
	void run()
	{
	  kprintfln!("hit here")();
		//schedule();
	  	Environment* temp = theQueue.peek();
		curEnvironment = temp;

		kprintfln!("Scheduler: About to jump to user at {x}")(curEnvironment.entry);


		// set up interrupt handler
		//Timer.initTimer(quantumInterval, &quantumFire);

		kprintfln!("environ stack: {x}")(curEnvironment.stackPtr);

		//Timer.initTimer(quantumInterval, &quantumFire);


		curEnvironment.preamble();
		curEnvironment.execute();
	
		mixin(Syscall.jumpToUser!("curEnvironment.stackPtr", "curEnvironment.entry"));
	}
}
