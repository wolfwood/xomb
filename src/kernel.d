/**
This file declares the main kernel code for XOmB.
The original purpose of this code is to boot the system, check for memory errors in booting,
and print out information to assist in debugging processor problems.

Written: 2007
*/
module kernel;

import config;
import elf;
import kgdb_stub;
import syscall;
import multiboot;
import system;
import util;
import vga;
import vmem;
static import gdt;
static import idt;

/**
This method sets sets the Input/Output Permission Level to 3, so
that it will not check the IO permissions bitmap when access is requested.
*/
void set_rflags_iopl()
{
	/* popf RFLAGS to set (IOPL) bits 12 & 13 = 1 */
	/* 0x3000 = 11000000000000 => bits 12 and 13 are 1*/
	asm
	{
		"pushf";
		"popq %%rax";
		"or $0x3000, %%rax";
		"pushq %%rax";
		"popf";
	}
}

/**
This is the main function of PGOS. It is executed once GRUB loads
fully. It accepts "magic," the magic number of the GRUB bootloader,
and "addr," the address of the multiboot variable, passed by the GRUB bootloader.
	Params:
		magic = the magic number returned by the GRUB bootloader
		addr = the address of the multiboot header, passed to the kernel to by the
			GRUB bootloader.
*/
extern(C) void cmain(uint magic, uint addr)
{
        int mb_flag = 0;

	// set flags.
	set_rflags_iopl();

	// install the Global Descriptor Table (GDT) and the Interrupt Descriptor Table (IDT)
	gdt.install();
	idt.install();

	idt.setCustomHandler(idt.Type.PageFault, &handle_faults);

	if(enable_kgdb)
	{
		set_debug_traps();
		breakpoint();
	}

	// Turn general interrupts on, so the computer can deal with errors and faults.
	asm { sti; }

	// Clear the screen in order to begin printing.
	// Console.cls();

	// Print initial booting information.
	kprintf("Booting ");
	Console.setColors(Color.Black, Color.HighRed);
	kprintf("PaGanOS");
	Console.resetColors();
	kprintfln("...\n");

        // Make sure the multiboot header is valid
        // and print out memory info, etc
	mb_flag = multiboot.test_mb_header(magic, addr);
        if (mb_flag) { // The mb header is bad!!!! Die!!!!
            kprintfln("Multiboot header is bad... DIE!");
            return;
        }

	// Print out our slogan. Literally, "We came, we saw, we conquered."
	Console.setColors(Color.Yellow, Color.LowBlue);
	kprintfln("\nVenimus, vidimus, vicimus!  --PittGeeks");
	Console.resetColors();

	// Set up the heap memory allocator
	vmem.setup_vmem_bitmap(addr);
        vmem.test_vmem();

	if(!(cpuid(0x8000_0001) & 0b1000_0000_0000))
	{
		kprintfln("Your computer is not cool enough, we need SYSCALL and SYSRET.");
		asm { cli; hlt; }
	}

	kprintfln("Setting lstar, star and SF_MASK...");

	syscall.setHandler(&syscall.sysCallHandler);

	kprintfln("JUMPING TO USER MODE!!!");

	asm
	{
		// Jump to user mode.
		"movq $testUser, %%rcx" ::: "rcx";
		"movq $0, %%r11" ::: "r11";
		"sysretq";
	}

	kprintfln("BACK!!!");
	
}



extern(C) void testUser()
{
        // let's not loop forever.  Do not want (yet).
        int numIters = 10;
        
	kprintfln("In User Mode.");

	for (int i = 0; i<numIters; i++)
	{

	    asm
	    {
		naked;
		"syscall";
	    }

	    kprintfln("Once more in user mode.");

	}
		
}