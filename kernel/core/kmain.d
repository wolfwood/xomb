/* XOmB Bare Bones
 *
 * This is the bare minimum needed for an OS written in the D language.
 *
 * Note: The kmain will be called in the higher memory region.
 *       The next step is setting up permanent kernel structures.
 *
 */

module kernel.core.kmain;

// This module contains our powerful kprintf function
import kernel.core.kprintf;

//handle everything that the boot loader gives us
import kernel.system.info;

//we need to print log stuff to the screen
import kernel.core.log;

// The main function for the kernel.
// This will receive data from the boot loader.

// bootLoaderID is the unique identifier for a boot loader.
// data is a structure given by the boot loader.

// For GRUB: the identifier is the magic number.
//           data is the pointer to the multiboot structure.
extern(C) void kmain(int bootLoaderID, void *data)
{

  //first, we'll print out some fun status messages.
	kprintfln!("{!cls}Welcome to {}! (version {}.{}.{})")("XOmB", 0,5,0);
  kprintfln!("{x} {x}")(bootLoaderID, data);
  //printToLog(hr);

  kprintfln!("size: {}")(uint.sizeof);

  //first, we would validate all of the bootloader stuff
  //and do the things that we need to do with it
  //printToLog("Verifying Multiboot information", handleMultibootInformation(bootLoaderID, data));


	// 2) Architecture Initialization (PASS / FAIL)

	// 3) Processor Initialization (PASS / FAIL)

	// 4) Timer Initialization (PASS / FAIL)

	// 5) Scheduler Initialization (PASS / FAIL)

	// 6) Multiprocessor Initialization (PASS / FAIL)

	// 7) Invoke Scheduler

	for(;;) {}

}
