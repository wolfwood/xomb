/* XOmB
 *
 * This is the main function for the XOmB Kernel
 *
 */

module kernel.core.kmain;

// Import the architecture-dependent interface
import architecture;

// This module contains our powerful kprintf function
import kernel.core.kprintf;

//handle everything that the boot loader gives us
import kernel.system.bootinfo;

// handle loading executables from modules
import kernel.system.loader;

// Scheduler
import kernel.environ.scheduler;

//we need to print log stuff to the screen
import kernel.core.log;

// kernel heap
import kernel.mem.heap;

// The main function for the kernel.
// This will receive data from the boot loader.

// bootLoaderID is the unique identifier for a boot loader.
// data is a structure given by the boot loader.
extern(C) void kmain(int bootLoaderID, void *data)
{

	//first, we'll print out some fun status messages.
	kprintfln!("{!cls!fg:White}Welcome to {!fg:Green}{}{!fg:White}! (version {}.{}.{})")("XOmB", 0,5,0);
	kprintfln!("{x} {x}")(bootLoaderID, data);
	//printToLog(hr);

	kprintfln!("size: {}")(uint.sizeof);

	// 1. Bootloader Validation
	printToLog("Initializing Boot Information", BootInfo.initialize(bootLoaderID, data));

	// 2. Architecture Initialization
	printToLog("Initializing Architecture", Architecture.initialize());

	// Initialize the kernel Heap
	Heap.initialize();

	// 2b. Paging Initialization
	printToLog("Initializing Virtual Memory", VirtualMemory.initialize());

	// 3. Processor Initialization
	printToLog("Initializing Processor", Cpu.initialize());

	// 4. Timer Initialization
	// LATER

	// 5. Scheduler Initialization
	// LATER

	// 6. Multiprocessor Initialization
	printToLog("Initializing Multiprocessor", Multiprocessor.initialize());

	// 7. Schedule
	
	Loader.loadModules();

	Scheduler.initialize();
	Scheduler.schedule();

	Scheduler.execute();

	// Run task

	for(;;) { }

}

extern(C) void apEntry() {

	// 1. Processor Initialization
	Cpu.initialize();

	// 2. Core Initialization
	Multiprocessor.installCore(1);

	// 2. Schedule
	for(;;) { }
}
