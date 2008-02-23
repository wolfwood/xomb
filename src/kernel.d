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
import lstar;
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
	setup_vmem_bitmap(addr);
	// Request a page for testing
	void* someAddr = request_page();
	void* someAddr2 = request_page();
	// Print the address for debug
	kprintfln("The address is 0x%x\n", someAddr);
	kprintfln("The address is 0x%x\n", someAddr2);

	free_page(someAddr2);

	void* someAddr3 = request_page();
	kprintfln("The address is 0x%x\n", someAddr3);

	if(!(cpuid(0x8000_0001) & 0b1000_0000_0000))
	{
		kprintfln("Your computer is not cool enough, we need SYSCALL and SYSRET.");
		asm { cli; hlt; }
	}

	const ulong STAR = 0x003b_0010_0000_0000;
	const uint STARHI = STAR >> 32;
	const uint STARLO = STAR & 0xFFFFFFFF;

	kprintfln("Setting lstar and star...");

	lstar.setHandler(&sysCallHandler);

	asm
	{
		// Set the STAR register.
		"movl $0xC0000081, %%ecx\n"
		"movl %0, %%edx\n"
		"movl %1, %%eax" :: "i"STARHI, "i"STARLO : "ecx", "edx", "eax";
		//"movl $0xC0000081, %%ecx" ::: "ecx";
		//"movl %0, %%edx" :: "i" STARHI : "edx";
		//"movl %0, %%eax" :: "i" STARLO : "eax";
		"wrmsr";
	}

	kprintfln("Setting SF_MASK...");

	asm
	{
		// Set the SF_MASK register.  Top should be 0, bottom is our mask,
		// but we're not masking anything (yet).
		"xorl %%eax, %%eax" ::: "eax";
		"xorl %%edx, %%edx" ::: "edx";
		"movl $0xC0000084, %%ecx" ::: "ecx";
		"wrmsr";
	}

	kprintfln("JUMPING TO USER MODE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");

	asm
	{
		// Jump to user mode.
		"movq $testUser, %%rcx" ::: "rcx";
		"movq $0, %%r11" ::: "r11";
		"sysretq";
	}

	kprintfln("BACK!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
	
}

void sysCallHandler()
{
	// we should get arguments and retain %rcx
	asm
	{
		naked;
		// etc: "popq %rdi";

		// push program counter to stack
		"pushq %%rcx";
	}

	kprintfln("In sysCall Handler");

	asm
	{
		naked;		
		"popq %%rcx";
		"sysretq";
	}
}

extern(C) void testUser()
{
	kprintfln("In User Mode.");

	for (;;)
	{

	asm
	{
		naked;
		"syscall";
	}

	kprintfln("Once more in user mode.");

	}
}

/**
This method allows the kernel to execute a module loaded using GRUB multiboot. It accepts 
a pointer to the GRUB Multiboot header as well as an integer, indicating the number of the module being loaded.
It then goes through the ELF header of the loaded module, finds the location of the _start section, and
jumps to it, thus beginning execution.

Params:
	moduleNumber = The number of the module the kernel wishes to execute. Integer value.
	mbi = A pointer to the multiboot information structure, allowing this function
		to interperet the module data properly.
*/
void jumpTo(uint moduleNumber, multiboot_info_t* mbi)
{
	// get a pointer to the loaded module.
	module_t* mod = &(cast(module_t*)mbi.mods_addr)[moduleNumber];

	// get the memory address of the module's starting point.
	// also, get a pointer to the module's ELF header.
	void* start = cast(void*)mod.mod_start;
	Elf64_Ehdr* header = cast(Elf64_Ehdr*)start;

	// find all the sections in the module's ELF Section header.
	Elf64_Shdr[] sections = (cast(Elf64_Shdr*)(start + header.e_shoff))[0 .. header.e_shnum];
	Elf64_Shdr* strTable = &sections[header.e_shstrndx];

	// go to the first section in the section header.
	Elf64_Shdr* text = &sections[1];

	// declare a void function which can be called to jump to the memory position of
	// __start().
	void function() entry = cast(void function())(start + text.sh_offset);
	entry();
}
