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
import kernel.core.multiboot;



// The main function for the kernel.
// This will receive data from the boot loader.

// bootLoaderID is the unique identifier for a boot loader.
// data is a structure given by the boot loader.

// For GRUB: the identifier is the magic number.
//           data is the pointer to the multiboot structure.
extern(C) void kmain(int bootLoaderID, void *data)
{

	kprintfln!("{!cls}Welcome to {}! (version {}.{}.{})")("XOmB", 0,5,0);

	kprintfln!("{x} {x}")(bootLoaderID, data);

  //first, we would validate all of the bootloader stuff
  //and do the things that we need to do with it
  handleMultibootInformation(bootLoaderID, data);

  //initialize architecture

  //set up timer

  //multi-core boot

  //system calls

  //scheduler


	for(;;) {}

}
