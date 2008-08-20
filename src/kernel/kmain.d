/**
This file declares the main kernel code for XOmB.
The original purpose of this code is to boot the system, check for memory errors in booting,
and print out information to assist in debugging processor problems.

Written: 2007
*/
module kernel.kmain;

// log
import kernel.log;

import kernel.mem.vmem;
import kernel.mem.pmem;

import kernel.core.multiboot;

import kernel.dev.vga;

//imports
import config;

import gdb.kgdb_stub;

import kernel.arch.select;

import kernel.error;
import kernel.core.elf;
import kernel.core.system;
import kernel.core.util;
import multiboot = kernel.core.multiboot;

import lapic = kernel.dev.lapic;

import mp = kernel.dev.mp;

/**
This is the main function of PGOS. It is executed once GRUB loads
fully. It accepts "magic," the magic number of the GRUB bootloader,
and "addr," the address of the multiboot variable, passed by the GRUB bootloader.
	Params:
		magic = the magic number returned by the GRUB bootloader
		addr = the address of the multiboot header, passed to the kernel to by the
			GRUB bootloader.
*/

	kmutex apMutex;

extern(C) void kmain_ap()
{
	apMutex.lock();
	printLogSuccess();
	apMutex.unlock();

	for(;;) { }
}

extern(C) void kmain(uint magic, uint addr)
{	
	auto mbi = cast(multiboot_info_t*)addr;
	int mb_flag = 0;

	// Clear the screen in order to begin printing.
	Console.cls();

	// Print initial booting information.
	Console.setColors(Color.LowGreen, Color.Black);
	kprintf!(" XOmB 0.0")();
	Console.resetColors();
	kprintf!("                               ")();

	// Print out our slogan. Literally, "We came, we saw, we conquered."
	Console.setColors(Color.Yellow, Color.LowBlue);
	kprintfln!("Venimus, vidimus, vicimus!  --PittGeeks\n")();
	Console.resetColors();

	// Make sure the multiboot header is valid
	// and print out memory info, etc
	printLogLine("Checking Multiboot Information");
	mb_flag = multiboot.test_mb_header(magic, addr);
	if (mb_flag) { // The mb header is bad!!!! Die!!!!
		printLogFail();
		return;
	}
	printLogSuccess();

	if(enable_kgdb)
	{
		printLogLine("Enabling kgdb");
		set_debug_traps();
		breakpoint();
		printLogSuccess();
	}

	// check to see if the CPU has the features we require
	// if this fails, the CPU will hang.
	Cpu.validate();

	// boot and initialize the primary CPU
	Cpu.boot();

	printLogLine("Installing Heap Allocator");
	// Set up the heap memory allocator
	if (pMem.install(mbi) == ErrorVal.Success)
	{
		printLogSuccess();
	}
	else
	{
		printLogFail();
	}

	//pMem.test();

	printLogLine("Installing Page Tables");
	vMem.install();
	printLogSuccess();

	// Turn general interrupts on, so the computer can deal with errors and faults.
	Cpu.enableInterrupts();

	//kprintfln!("Setting lstar, star and SF_MASK...")();

	printLogLine("Installing Syscall Handler");
	syscall.setHandler(&syscall.syscallHandler);
	printLogSuccess();



	// TESTING MUTEXES
	printLogLine("Testing Kernel Locks");
	int failcode = test_kmutex();
	if (failcode == 0)
	{
		printLogSuccess();
	}
	else
	{
		printLogFail();	
	}

	apMutex.lock();

	// initialize multiprocessor information
	mp.init();

	// initialize APIC
	mp.initAPIC();


	printLogLine("The second CPU will post OK");
	apMutex.unlock();
	apMutex.lock();	

	kprintfln!("")();

	kprintfln!("Jumping to User Mode...\n")();

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
	kprintfln!("In User Mode.")();
// 
// 	auto ptr = cast(long*)0x1000;
// 
// 	if(cast(SyscallError)user.syscall.allocPage(ptr) == SyscallError.OK)
// 	{
// 		kprintfln!("!!Page allocation succeeded!!  Testing..")();
// 
// 		ptr[0] = 5;
// 		kprintfln!("ptr[0] = {}")(ptr[0]);
// 	}
// 	else
// 		kprintfln!("Page allocation failed..")();

	user.syscall.exit(0);

	while(true)
	{
	}
}
