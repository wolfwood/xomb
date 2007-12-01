/** kernel.d
	This file declares the main kernel code for XOmB.
	The original purpose of this code is to boot the system, check for memory errors in booting,
	and print out information to assist in debugging processor problems.

	Written: 2007
 */


import multiboot;
import vga;
import system;
import gdt;
static import idt;
import elf;
import lstar;
import vmem;
import kgdb_stub;
import config;

/**
This method checks to see if the value stored in the bit number declared
by the input variable "bit" in the flag declared by the input
variable "flags" is set. Returns a 1 if it is set, returns a 0 if it is not set.
	Params:
		flags = The flags from the multiboot header the kernel wishes to check.
		bit = The number of the bit the kernel would like to check for data.
	Returns: Whether the bit "bit" in "flags" has a value (1 if it is set, 0 if it is not)
*/
uint CHECK_FLAG(uint flags, uint bit)
{
	return ((flags) & (1 << (bit)));
}

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

uint cpuid(uint func)
{
	asm
	{
		naked;
		"movl %%edi, %%eax";
		"cpuid";
		"movl %%edx, %%eax";
		"retq";
	}
}

/*
Func 0: 69746e65
Func 80000001: 2bd0ab7b = 0010_1011_1101_0000_1010_1011_0111_1011
	31: n 3dnow
	30: n 3dnowext
	29: y longmode
	28: - reserved

	27: y rdtscp inst
	26: n page1gb
	25: y FFXSR
	24: y FXSR
	
	23: y MMX
	22: y MmxExt
	21: - reserved
	20: y NX

	19: - reserved
	18: - reserved
	17: n PSE36
	16: n PAT

	15: y CMOV
	14: n MCA
	13: y PGE
	12: n MTRR

	11: y SYSCALL/RET
	10: - reserved
	 9: y
	 8: y
	 
	 7: n
	 6: y
	 5: y
	 4: y
	 
	 3: y
	 2: n
	 1: y
	 0: y
*/

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
	/// declare a pointer to the multiboot header.
	multiboot_info_t *mbi;

	/// set flags.
	set_rflags_iopl();

	/// install the Global Descriptor Table (GDT) and the Interrupt Descriptor Table (IDT)
	GDT.install();
	idt.install();

	idt.setCustomHandler(idt.Type.PageFault, &handle_faults);

	if( enable_kgdb ){
		set_debug_traps();
		breakpoint();
	}

	/// Create a handler to deal with data in the LSTAR memory location. This handler
	/// will deal with system interrupts.
	lstar.set_handler(&lstar.syscallHandler);

	/// Turn general interrupts on, so the computer can deal with errors and faults.
	asm{sti;}

	/// Clear the screen in order to begin printing.
	/// Console.cls();

	/// Print initial booting information.
	kprintf("Booting ");
	Console.setColors(Color.Black, Color.HighRed);
	kprintf("PaGanOS");
	Console.resetColors();
	kprintfln("...\n");

	/// Make sure that the magic number, passed to the kernel, is a valid GRUB magic number.
	/// If it is not, print to the screen that the magic number is invalid and end execution.
	/// Invalid magic numbers can indicate that the system was illegally booted, or that the 
	// system was booted by a bootloader other than GRUB.
	if(magic != MULTIBOOT_BOOTLOADER_MAGIC)
	{
		kprintfln("Invalid magic number: 0x%x", cast(uint)magic);
		return;
	}

	/// Set MBI to the address of the Multiboot information structure, passed to the kernel
	/// by GRUB.
	mbi = cast(multiboot_info_t*)addr;

	/// Print out all the values of the flags presented to the operating system by GRUB.
	kprintfln("flags = 0x%x", cast(uint)mbi.flags);

	/// Are mem_* valid
	if(CHECK_FLAG(mbi.flags, 0))
		kprintfln("mem_lower = %uKB, mem_upper = %uKB", cast(uint)mbi.mem_lower, cast(uint)mbi.mem_upper);

	/// Check to make sure the boot device is valid.
	if(CHECK_FLAG(mbi.flags, 1))
		kprintfln("boot_device = 0x%x", cast(uint)mbi.boot_device);

	/// Is the command line passed?
	if(CHECK_FLAG(mbi.flags, 2))
		kprintfln("cmdline = %s", system.toString(cast(char*)mbi.cmdline));

	/// This if statement calls the function CHECK_FLAG on the flags of the GRUB multiboot header.
	/// It then checks to make sure the flags are valid (indicating proper, secure booting).
	if(CHECK_FLAG(mbi.flags, 3))
	{
		/// print out the number of modules loaded by GRUB, and the physical memory address of the first module in memory.
		kprintfln("mods_count = %d, mods_addr = 0x%x", cast(int)mbi.mods_count, cast(int)mbi.mods_addr);

		module_t* mod;
		int i;

		/// Go through all of the modules loaded by GRUB.
		for(i = 0, mod = cast(module_t*)mbi.mods_addr; i < mbi.mods_count; i++, mod++)
		{
			/// print out the memory address of the beginning of that module, the address of the end of that module,
			/// and the name of that module.
			kprintfln(" mod_start = 0x%x, mod_end = 0x%x, string = %s",
				cast(uint)mod.mod_start,
				cast(uint)mod.mod_end,
				system.toString(cast(char*)mod.string));
		}

		/// Use the jumpTo() method (see below) to execute the first module.
		//jumpTo(0, mbi);
		//return;
	}

	/// Bits 4 and 5 are mutually exclusive!
	if(CHECK_FLAG(mbi.flags, 4) && CHECK_FLAG(mbi.flags, 5))
	{
		kprintfln("Both bits 4 and 5 are set.");
		return;
	}

	/// Check to make sure the symbol table of the compiled kernel file is valid.
	if(CHECK_FLAG(mbi.flags, 4))
	{
		/// get a pointer to the symbol table, returned by GRUB in the multiboot header.
		aout_symbol_table_t* aout_sym = &(mbi.aout_sym);

		/// If it is valid, print out information about the compiled kernel's symbol table.
		kprintfln("aout_symbol_table: tabsize = 0x%0x, strsize = 0x%x, addr = 0x%x",
			cast(uint)aout_sym.tabsize,
			cast(uint)aout_sym.strsize,
			cast(uint)aout_sym.addr);
	}

	/// Check to make sure the section header of the compiled kernel is valid.
	if(CHECK_FLAG(mbi.flags, 5))
	{
		elf_section_header_table_t* elf_sec = &(mbi.elf_sec);

		/// If it is valid, print out information about the compiled kernel's section table.
		kprintfln("elf_sec: num = %u, size = 0x%x, addr = 0x%x, shndx = 0x%x",
			cast(uint)elf_sec.num, cast(uint)elf_sec.size,
			cast(uint)elf_sec.addr, cast(uint)elf_sec.shndx);
	}

	/// This checks to make sure that the memory map of the bootloader is valid.
	if(CHECK_FLAG(mbi.flags, 6))
	{
		kprintfln("mmap_addr = 0x%x, mmap_length = 0x%x", cast(uint)mbi.mmap_addr, cast(uint)mbi.mmap_length);

		for(memory_map_t* mmap = cast(memory_map_t*)mbi.mmap_addr;
			cast(uint)mmap < mbi.mmap_addr + mbi.mmap_length;
			mmap = cast(memory_map_t*)(cast(uint)mmap + mmap.size + uint.sizeof))
		{
			kprintfln(" size = 0x%x, base_addr = 0x%x%x, length = 0x%x%x, type = 0x%x",
				cast(uint)mmap.size,
				cast(uint)mmap.base_addr_high,
				cast(uint)mmap.base_addr_low,
				cast(uint)mmap.length_high,
				cast(uint)mmap.length_low,
				cast(uint)mmap.type);
		}
	}

	/// Print out our slogan. Literally, "We came, we saw, we conquered."
	Console.setColors(Color.Yellow, Color.LowBlue);
	kprintfln("\nVenimus, vidimus, vicimus!  --PittGeeks");
	Console.resetColors();

	/// Print out memory information, including the size of system integers. This
	/// will let us debug problems in changing from 32-bit to 64-bit.
	kprintfln("(int*).sizeof == %d", (int*).sizeof);
	
	fourK_pages(addr);
	

	/// This value prints out an indication that the operating system is purposely throwing
	/// a 128 interrupt (system call interrupt).
	// kprintfln("TESTING SYSCALL INTERRUPT");
	// asm{int 128;}
	
	/// This is alternate code, attempting to call a system call without a 128 interrupt.
	// first, set a syscall type into eax.
	kprintf("SETTING EAX TO 0\n");

	asm {
		"mov %0, %%eax":
		/* no output */:
		"r" 1:
		"eax";
	}

	kprintf("CALLING THE SYSCALL.\n");
	asm {
		"syscall";
	}
	
	if(cpuid(0x8000_0001) & 0b1000_0000_0000)
	{
		//ulong STAR = 0b0000_0000_0011_1011_0000_0000_0001_0000_00000000000000000000000000000000;
		const ulong STAR = 0x003b_0010_0000_0000;
		//const ulong LSTAR = cast(ulong)&sysCallHandler;

		//const uint LSTARHI = LSTAR >> 32;
		//const uint LSTARLO = LSTAR & 0xFFFFFFFF;
		
		const uint STARHI = STAR >> 32;
		const uint STARLO = STAR & 0xFFFFFFFF;

		asm
		{
			"movq $sysCallHandler, %%rdx" ::: "rdx";
			"xorq %%rax, %%rax";
			"movl %%edx, %%eax";
			"shrq $32, %%rdx";
			"wrmsr";

			"movl $0xC0000081, %%ecx" ::: "ecx";
			"movl %0, %%edx" :: "i" STARHI : "edx";
			"movl %0, %%eax" :: "i" STARLO : "eax";
			"wrmsr";
			
			"xorl %%eax, %%eax" ::: "eax";
			"xorl %%edx, %%edx" ::: "edx";
			"movl $0xC0000084, %%ecx" ::: "ecx";
			"wrmsr";

			"movq $testUser, %%rcx" ::: "rcx";
			"movq $0, %%r11" ::: "r11";
			"sysretq";
		}


		asm { cli; hlt; }
	}
	else
	{
		kprintfln("Your computer is not cool enough, we need SYSCALL and SYSRET.");
		asm { cli; hlt; }
	}

	/// CURRENT TEST CODE
	// int a = 0, b = cast(int) addr;
	// int foo = b/a;
	// kprintfln("%d", foo);
}

extern(C) void sysCallHandler()
{
	asm
	{
		naked;
		"sysretq";
	}
}

void* p;

extern(C) void testUser()
{
	asm
	{
		naked;
		"syscall";
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
	/// get a pointer to the loaded module.
	module_t* mod = &(cast(module_t*)mbi.mods_addr)[moduleNumber];
	
	/// get the memory address of the module's starting point.
	/// also, get a pointer to the module's ELF header.
	void* start = cast(void*)mod.mod_start;
	Elf64_Ehdr* header = cast(Elf64_Ehdr*)start;

	/// find all the sections in the module's ELF Section header.
	Elf64_Shdr[] sections = (cast(Elf64_Shdr*)(start + header.e_shoff))[0 .. header.e_shnum];
	Elf64_Shdr* strTable = &sections[header.e_shstrndx];
	
	/// go to the first section in the section header.
	Elf64_Shdr* text = &sections[1];

	/// declare a void function which can be called to jump to the memory position of
	/// __start().
	void function() entry = cast(void function())(start + text.sh_offset);
	entry();
}
