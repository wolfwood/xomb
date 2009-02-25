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

// The main function for the kernel.
// This will receive data from the boot loader.

// bootLoaderID is the unique identifier for a boot loader.
// data is a structure given by the boot loader.

// For GRUB: the identifier is the magic number.
//           data is the pointer to the multiboot structure.
extern(C) void kmain(int bootLoaderID, void *data)
{
	// 1) Convert bootloader information to Kernel Friendly information

	kprintfln!("{!cls} boot loader id: {x} data: {x}")(bootLoaderID, data);

	// 2) Architecture Initialization (PASS / FAIL)

	// 3) Processor Initialization (PASS / FAIL)

	// 4) Timer Initialization (PASS / FAIL)

	// 5) Scheduler Initialization (PASS / FAIL)

	// 6) Multiprocessor Initialization (PASS / FAIL)

	// 7) Invoke Scheduler

	for(;;) {}

}
