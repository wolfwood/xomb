// scheduler.d 
//

module kernel.environment.scheduler;

import kernel.core.multiboot;			// GRUB multiboot
import kernel.core.elf;					// ELF code
import kernel.core.modules;				// GRUB modules

import kernel.arch.select;				// architecture dependent

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

		// set up quantum timer
		// set up interrupt handler

		HPET.initTimer(0, quantumInterval, &quantumFire);

		// add a new environment
		Environment* environ;
		EnvironmentTable.newEnvironment(environ);

		// load an executable from the multiboot header
		environ.loadGRUBModule(0);

		return ErrorVal.Success;
	}

	// called when the quantum fires
	void quantumFire(interrupt_stack* stack)
	{
		// schedule!
		schedule();

		HPET.resetTimer(0, quantumInterval);
	}

	// called to schedule a new process
	void schedule()
	{
	}

	// called at the first run
	void run()
	{
		curEnvironment = EnvironmentTable.getEnvironment(0);

		kprintfln!("Scheduler: About to jump to user at {x}")(curEnvironment.entry);

		syscall.jumpToUser(curEnvironment.entry);
	}
}
