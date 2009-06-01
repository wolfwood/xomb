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

//we need to print log stuff to the screen
import kernel.core.log;

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

	// 3. Processor Initialization
	printToLog("Initializing Processor", Cpu.initialize());

	// 4. Timer Initialization
	// LATER

	// 5. Scheduler Initialization
	// LATER

	// 6. Multiprocessor Initialization
	printToLog("Initializing Multiprocessor", Multiprocessor.initialize());

	// 7. Schedule

	for(;;) { kprintfln!("OMG LOOP")(); }

}
