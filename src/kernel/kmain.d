/**
This file declares the main kernel code for XOmB.
The original purpose of this code is to boot the system, check for memory errors in booting,
and print out information to assist in debugging processor problems.

Written: 2007
*/
module kernel.kmain;


//imports
import config;

import gdb.kgdb_stub;

import kernel.core.elf;
import kernel.core.system;
import kernel.core.util;
import multiboot = kernel.core.multiboot;

import syscall = kernel.syscall;
import kernel.vga;
static import gdt = kernel.gdt;
static import idt = kernel.idt;

import vmem = kernel.mem.vmem;
import pmem = kernel.mem.pmem;
import kernel.mem.vmem_structs;

import locks = kernel.locks;

import mp = kernel.dev.mp;
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
extern(C) void kmain(uint magic, uint addr)
{
	int mb_flag = 0;

	// set flags.
	set_rflags_iopl();

	// install the Global Descriptor Table (GDT) and the Interrupt Descriptor Table (IDT)
	gdt.install();
	idt.install();

	idt.setCustomHandler(idt.Type.PageFault, &vmem.handle_faults);

	if(enable_kgdb)
	{
		set_debug_traps();
		breakpoint();
	}

	// Turn general interrupts on, so the computer can deal with errors and faults.
	
	asm { 
	
		//sti;

	}

	// Clear the screen in order to begin printing.
	Console.cls();

	// Print initial booting information.
	kprintf!("Booting ")();
	Console.setColors(Color.Black, Color.HighRed);
	kprintf!("PaGanOS")();
	Console.resetColors();
	kprintfln!("...\n")();

	// Make sure the multiboot header is valid
	// and print out memory info, etc
	mb_flag = multiboot.test_mb_header(magic, addr);
	if (mb_flag) { // The mb header is bad!!!! Die!!!!
		kprintfln!("Multiboot header is bad... DIE!")();
		return;
	}

	// Print out our slogan. Literally, "We came, we saw, we conquered."
	Console.setColors(Color.Yellow, Color.LowBlue);
	kprintfln!("\nVenimus, vidimus, vicimus!  --PittGeeks")();
	Console.resetColors();

	// Set up the heap memory allocator
	pmem.setup_pmem_bitmap(addr);
	//pmem.test_pmem();
	vmem.reinstall_kernel_page_tables(addr);

	void* t = cast(void*)0x0000000000100000;
	void* t2 = cast(void*)0x0000000000110000;
	void* t3 = cast(void*)0x0000000000100000;

	//int test = vmem.get_page(t);
	//int test2 = vmem.get_page(t2);
	//int test3 = vmem.get_page(t3);

	//kprintfln!("test1 = {}")(test);
	//kprintfln!("test2 = {}")(test2);
	//kprintfln!("test3 = {}")(test3);
	//vmem.free_page(t);
	//test = vmem.get_page(t);
	//kprintfln!("virtual page requested a second time, address = {x}")(test);
	//kprintfln!("releasing test1")();
	//vmem.free_page(t);
	//kprintfln!("releasing test2")();
	//vmem.free_page(t2);
	//vmem.free_page(t3);

	if(!(cpuid(0x8000_0001) & 0b1000_0000_0000))
	{
		kprintfln!("Your computer is not cool enough, we need SYSCALL and SYSRET.")();
		asm { cli; hlt; }
	}

	//kprintfln!("Setting lstar, star and SF_MASK...")();

	syscall.setHandler(&syscall.syscallHandler);

	// TESTING MUTEXES
	//kprintfln!("Starting kmutex test")();
	int failcode = locks.test_kmutex();
	//kprintfln!("KMUTEX test code (0 is good): {}")(failcode);
	//want to see the result:   
	//return;

	kprintfln!("Testing bios memory regions!")();
	kprintfln!("Bios region phys_start / length / virt_start = 0x{x} / 0x{x} / 0x{x}")(global_mem_regions_t.system_memory.physical_start, 
																				  global_mem_regions_t.system_memory.length,
																				  global_mem_regions_t.system_memory.virtual_start);
	
	mp.init();

	kprintfln!("JUMPING TO USER MODE!!!")();

	asm
	{
		// Jump to user mode.
		"movq $testUser, %%rcx" ::: "rcx";
		"movq $0, %%r11" ::: "r11";
		"sysretq";
	}

	kprintfln!("BACK!!!")();
}

import user.syscall;

extern(C) void testUser()
{
	// let's not loop forever.  Do not want (yet).
	int numIters = 10;

	kprintfln!("In User Mode.")();

	auto ptr = cast(long*)0x1000;

	if(cast(SyscallError)user.syscall.allocPage(ptr) == SyscallError.OK)
	{
		kprintfln!("!!Page allocation succeeded!!  Testing..")();

		ptr[0] = 5;
		kprintfln!("ptr[0] = {}")(ptr[0]);
	}
	else
		kprintfln!("Page allocation failed..")();

	user.syscall.exit(0);

	while(true)
	{
	}
}
