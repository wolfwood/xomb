/* XOmB
 *
 * This is the main function for the XOmB Kernel
 *
 */

module kernel.core.kmain;

// Import the architecture-dependent interface
import architecture.cpu;
import architecture.multiprocessor;
import architecture.vm;
import architecture.syscall;
import architecture.main;
import architecture.perfmon;
import architecture.timing;

// This module contains our powerful kprintf function
import kernel.core.kprintf;
import kernel.core.error;

//handle everything that the boot loader gives us
import kernel.system.bootinfo;

// handle loading executables from modules
import kernel.system.loader;

// get basic info about the system
import kernel.system.info;

// Scheduler
import kernel.environ.scheduler;

//we need to print log stuff to the screen
import kernel.core.log;

// kernel heap
import kernel.mem.heap;

// kernel-side ramfs
import kernel.filesystem.ramfs;

// console device
import kernel.dev.console;

import kernel.core.syscall;


// The main function for the kernel.
// This will receive data from the boot loader.

// bootLoaderID is the unique identifier for a boot loader.
// data is a structure given by the boot loader.
extern(C) void kmain(int bootLoaderID, void *data) {

	//first, we'll print out some fun status messages.
	kprintfln!("{!cls!fg:White} Welcome to {!fg:Green}{}{!fg:White}! (version {}.{}.{})")("XOmB", 0,5,0);
	for(int i; i < 80; i++) {
		// 0xc4 -- horiz line
		// 0xcd -- double horiz line
		kprintf!("{}")(cast(char)0xcd);
	}
	//kprintfln!("--------------------------------------------------------------------------------")();
	//Log.print(hr);

	// 1. Bootloader Validation
	Log.print("BootInfo: initialize()");
	Log.result(BootInfo.initialize(bootLoaderID, data));

	// 2. Architecture Initialization
	Log.print("Architecture: initialize()");
   	Log.result(Architecture.initialize());

	// Initialize the kernel Heap
	Heap.initialize();

	Log.print("PerfMon: initialize()");
	Log.result(PerfMon.initialize());
	PerfMon.registerEvent(0, PerfMon.Event.L2Misses);

	Log.print("Timing: initialize()");
	Log.result(Timing.initialize());

	// 2b. Paging Initialization
	Log.print("VirtualMemory: initialize()");
   	Log.result(VirtualMemory.initialize());

	// 2c. Paging Install
	Log.print("VirtualMemory: install()");
	Log.result(VirtualMemory.install());

	// 3. Processor Initialization
	Log.print("Cpu: initialize()");
	Log.result(Cpu.initialize());

	// 3b. RamFS Initialization
	Log.print("RamFS: initialize()");
	Log.result(RamFS.initialize());

	// 3c. Console Initialization
	Log.print("Console: initialize()");
	Log.result(Console.initialize());

	// 4. Timer Initialization
	// LATER

	// 5. Scheduler Initialization
	// LATER

	// 6. Multiprocessor Initialization
	Log.print("Multiprocessor: initialize()");
	Log.result(Multiprocessor.initialize());
	//kprintfln!("Number of Cores: {}")(Multiprocessor.cpuCount);

	// 7. Syscall Initialization
	Log.print("Syscall: initialize()");
	Log.result(Syscall.initialize());

	Log.print("Multiprocessor: bootCores()");
	Log.result(Multiprocessor.bootCores());

	// 7. Schedule
	Scheduler.initialize();
	
	Loader.loadModules();

	Gib video2 = RamFS.open("/dev/video", Access.Read | Access.Write);
	RamFS.seek(video2, 4096);
	const ubyte[] foo = cast(ubyte[])['a', 42, 'b', 42, 'c', 42, '!', 42, '!', 42];
	RamFS.write(video2, foo.ptr, foo.length);

	Date dt;
	Timing.currentDate(dt);
	kprintfln!("Date: {} {} {}")(dt.day, dt.month, dt.year);

	Scheduler.kmainComplete();

	Scheduler.idleLoop();

	// Run task
	assert(false, "Something is VERY VERY WRONG. Scheduler.execute returned. :(");
}

extern(C) void apEntry() {

	// 0. Paging Initialization
	VirtualMemory.install();

	// 1. Processor Initialization
	Cpu.initialize();

	// 2. Core Initialization
	Multiprocessor.installCore();

	// 3. Schedule
	Scheduler.idleLoop();
	for(;;){}
}
