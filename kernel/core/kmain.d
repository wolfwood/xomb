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

// kernel-side ramfs
import kernel.filesystem.ramfs;


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
	//printToLog(hr);

	// 1. Bootloader Validation
	printToLog("BootInfo: initialize()", BootInfo.initialize(bootLoaderID, data));

	// 2. Architecture Initialization
	printToLog("Architecture: initialize()", Architecture.initialize());

	// Initialize the kernel Heap
	Heap.initialize();

	// 2b. Paging Initialization
	printToLog("VirtualMemory: initialize()", VirtualMemory.initialize());

	// 3. Processor Initialization
	printToLog("Cpu: initialize()", Cpu.initialize());

	// 4. Timer Initialization
	// LATER

	// 5. Scheduler Initialization
	// LATER

	// 6. Multiprocessor Initialization
	printToLog("Multiprocessor: initialize()", Multiprocessor.initialize());

	// 6b. RamFS Initialization
	printToLog("RamFS: initialize()", RamFS.initialize());

	Gib video = RamFS.create("/dev/video");
	ubyte* videoMetaData = cast(ubyte*)video;
	*(videoMetaData) = 1;
	video = cast(Gib)(videoMetaData + 4096);
	RamFS.mapRegion(video, cast(void*)0xB8000, 1028*1028);
	*(videoMetaData + 4096) = 'a';
	*(videoMetaData + 4098) = 'b';
	*(videoMetaData + 4100) = 'c';

	Gib video2 = RamFS.locate("/dev/video");
	RamFS.seek(video2, 4096);
	const ubyte[] foo = cast(ubyte[])['a', 42, 'b', 42, 'c', 42, '!', 42, '!', 42];
	RamFS.write(video2, foo.ptr, foo.length);

	kprintfln!("Number of Cores: {}")(Multiprocessor.cpuCount);

	// 7. Syscall Initialization
	printToLog("Syscall: initialize()", Syscall.initialize());

	printToLog("Multiprocessor: bootCores()", Multiprocessor.bootCores());

	// 7. Schedule
	Scheduler.initialize();
	
	Loader.loadModules();

	RamFS.create("/boot/testc");

	Scheduler.schedule();

	Scheduler.execute();

	// Run task
	assert(false, "Something is VERY VERY WRONG. Scheduler.execute returned. :(");
}

extern(C) void apEntry() {

	// 1. Processor Initialization
	Cpu.initialize();

	// 2. Core Initialization
	Multiprocessor.installCore(1);

	// 2. Schedule
	for(;;) { }
}
