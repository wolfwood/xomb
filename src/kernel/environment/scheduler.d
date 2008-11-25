// scheduler.d 
//

module kernel.environment.scheduler;

import kernel.core.multiboot;			// GRUB multiboot
import kernel.core.elf;					// ELF code
import kernel.core.modules;				// GRUB modules

// architecture dependent
import kernel.arch.interrupts;
import kernel.arch.timer;
import kernel.arch.syscall;
import kernel.arch.context;

import kernel.dev.vga;

import kernel.environment.table;		// for environment table

import kernel.core.error;				// for return values

struct Scheduler
{

static:
	
	// the quantum length in picoseconds
	const ulong quantumInterval = 50000000000;

	// TODO: probably need one per CPU...
	Environment* curEnvironment;

	ErrorVal init()
	{
		// set up environment table

		if (EnvironmentTable.init() == ErrorVal.Fail)
		{
			return ErrorVal.Fail;
		}

		// add a new environment
		Environment* environ;
		kprintfln!("Scheduler: Creating new environment.")();
		EnvironmentTable.newEnvironment(environ);

		// load an executable from the multiboot header
		kprintfln!("Scheduler: Loading from GRUB module.")();
		environ.loadGRUBModule(0);

		return ErrorVal.Success;
	}

	// called when the quantum fire
	void quantumFire(InterruptStack* stack)
	{
		// schedule!
		//schedule();

		Timer.resetTimer(0, quantumInterval);
	}

	// called to schedule a new process
	void schedule()
	{
		if (curEnvironment !is null) {
			// assume that the context switching code has been
			// done in these two places:

			// isr_common()
			// syscall_dispatcher()

			mixin(contextStackSave!("curEnvironment.stackPtr"));
		}

		// find candidate for execution
		
		// ... //
		curEnvironment = EnvironmentTable.getEnvironment(0);

		// curEnvironment should be set to the next
		// environment to be executed

		// restore the stack, this should already have the 
		// RIP to return from calling schedule()

		// the resulting return should get to the context
		// switch restore code for the architecture

		mixin(contextStackRestore!("curEnvironment.stackPtr"));
		curEnvironment.preamble();				

		// return
	}

	void exit()
	{
		EnvironmentTable.removeEnvironment(curEnvironment.id);

		curEnvironment = null;

		if (EnvironmentTable.count == 0) 
		{
			// cripes, no more environments
			// shut down!
			kprintfln!("Scheduler: No more environments.")();
			for(;;) {}
		}

		//schedule();
	}

	// called at the first run
	void run()
	{
		//schedule();
		curEnvironment = EnvironmentTable.getEnvironment(0);

		kprintfln!("Scheduler: About to jump to user at {x}")(curEnvironment.entry);

		// set up quantum timer
		// set up interrupt handler

	    //	curEnvironment = null;
		//Timer.initTimer(quantumInterval, &quantumFire);

		kprintfln!("environ stack: {x}")(curEnvironment.stackPtr);
	
		curEnvironment.preamble();

		mixin(Syscall.jumpToUser!("curEnvironment.stackPtr", "curEnvironment.entry"));
	}
}
