// scheduler.d 
//

module kernel.environment.scheduler;

import kernel.core.multiboot;			// GRUB multiboot
import kernel.core.elf;					// ELF code
import kernel.core.modules;				// GRUB modules

import kernel.util.queue;				// For environment queue

// architecture dependent
import kernel.arch.interrupts;
import kernel.arch.timer;
import kernel.arch.syscall;
import kernel.arch.context;

import kernel.dev.vga;

import kernel.environment.table;		// for environment table
import kernel.environment.cputable;		// for cpu table

import kernel.core.error;				// for return values

import config;							// for debug

// XXX: placed here because of weird D bug
const int MAX_ENVIRONMENTS = 1024;

struct Scheduler
{

static:
	
	// the quantum length in picoseconds
	const ulong quantumInterval = 50000000000;

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

		theQueue.init();

		// add a new environment
		// Get all grub modules and load them in to the environment table
		for(int i = 0; i < GRUBModules.length; i++) 
		{
			Environment* environ;
			kdebugfln!(DEBUG_SCHEDULER, "Scheduler: Creating new environment.")();

			EnvironmentTable.newEnvironment(environ);
			theQueue.push(environ);

			// load an executable from the multiboot header
			kdebugfln!(DEBUG_SCHEDULER, "Scheduler: Loading from GRUB module.")();

		  loadGRUBModule(environ, i);
		}

		Interrupts.setCustomHandler(Interrupts.Type.DivByZero, &quantumFire);

		return ErrorVal.Success;
	}

	// called when the quantum fire
	void quantumFire(InterruptStack* stack)
	{
		// schedule!
		//if (shouldSchedule) { schedule(); }
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

			postamble(curEnvironment);
		}

		// find candidate for execution

		kdebugfln!(DEBUG_SCHEDULER, "schedule(): Scheduling new environment.  Current eid: {}")(curEnvironment.id);
		
		// ... //
	//	curEnvironment = EnvironmentTable.getEnvironment(0);
	  //if(curEnvironment.id == 0) {
	    //curEnvironment = EnvironmentTable.getEnvironment(1);
	  //} else {
	    //curEnvironment = EnvironmentTable.getEnvironment(0);
	  //}

	  	kdebugfln!(DEBUG_SCHEDULER, "schedule(): New Environment Selected.  eid: {}")(curEnvironment.id);
	
		Environment* temp = theQueue.peek();
		curEnvironment = temp;
	
		// curEnvironment should be set to the next
		// environment to be executed

		// restore the stack, this should already have the 
		// RIP to return from calling schedule()

		// the resulting return should get to the context
		// switch restore code for the architecture

		preamble(curEnvironment);
		execute(curEnvironment);				

		// return
	}

	void yield()
	{
		kdebugfln!(DEBUG_SCHEDULER, "Yield from eid: {}")(curEnvironment.id);
//		curEnvironment.postamble();
		
	  //curEnvironment = EnvironmentTable.getEnvironment(0);
	  Environment* temp = theQueue.pop();
	  theQueue.push(temp);
	  schedule();

//	curEnvironment.preamble();
//	  curEnvironment.execute();

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
			kdebugfln!(DEBUG_SCHEDULER, "Scheduler: No more environments.")();
			for(;;) {}
		}

		schedule();
	}

	// called at the first run
	void run()
	{
		//schedule();
		//curEnvironment = EnvironmentTable.getEnvironment(0);
		curEnvironment = theQueue.peek();

		kdebugfln!(DEBUG_SCHEDULER, "Scheduler: About to jump to user at {x}")(curEnvironment.entry);


		// set up interrupt handler
		//Timer.initTimer(quantumInterval, &quantumFire);


		//Timer.initTimer(quantumInterval, &quantumFire);


		preamble(curEnvironment);
		execute(curEnvironment);
	
		mixin(Syscall.jumpToUser!());
	}

	void cpuReady(uint cpuID)
	{
		// this cpu is ready to be scheduled

		kdebugfln!(DEBUG_SCHEDULER, "Scheduler: cpu {} is awaiting orders.")(cpuID);

		CpuTable.provide(cpuID);
	}
}
