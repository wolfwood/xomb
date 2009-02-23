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

	kprintfln!("{!cls}{!fg:LightBlue}I will eat your {}! {}, {x}Cl{!bg:Blue}ea{!fg:White}red{!fg:LightGray!bg:Black}Cleared{!pos:10,10}{}!")("brains", 10, 3735928559, "BRAINS!!!");

	kprintfln!("hello world")();
	for(;;) {}

	kprintfln!("{x} {x}")(bootLoaderID, data);


	// Ok, so we don't want to just infinite loop (if you want it to do something)
	// Replace this with your kernel logic!

	for(;;) {}

}
