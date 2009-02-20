/**
This file declares the main kernel code for XOmB.
The original purpose of this code is to boot the system, check for memory errors in booting,
and print out information to assist in debugging processor problems.

Written: 2007
*/
module kernel.kmain;

// log
import kernel.core.log;

import kernel.arch.x86_64.vmem;
import kernel.mem.pmem;

import kernel.core.multiboot;

import kernel.dev.vga;
import kernel.dev.vesa;
import kernel.dev.keyboard;

//imports
import config;
import kernel.arch.x86_64.globals;

import gdb.kgdb_stub;

import kernel.error;
import kernel.core.elf;
import kernel.core.util;
import multiboot = kernel.core.multiboot;

import kernel.arch.locks;
import kernel.arch.multiprocessor;
import kernel.arch.timer;
import kernel.arch.cpu;

import kernel.environment.scheduler;
import kernel.environment.cputable;

/*
This is the main function of XOmB. It is executed once GRUB loads
fully. It accepts "magic," the magic number of the GRUB bootloader,
and "addr," the address of the multiboot variable, passed by the GRUB bootloader.
	Params:
		magic = the magic number returned by the GRUB bootloader
		addr = the address of the multiboot header, passed to the kernel to by the
			GRUB bootloader.
*/

extern(C) void kmain(uint magic, uint addr)
{
	auto mbi = cast(multiboot_info_t*)addr;
	int mb_flag = 0;

	// Clear the screen in order to begin printing.
	Console.cls(true);

	// Print initial booting information.
	Console.setColors(Color.HighGreen, Color.Black);
	kprintf!(" XOmB 0.0 $Rev$")();
	Console.resetColors();
	int x,y;
	Console.getPosition(x,y);
	Console.setPosition(80-40, y);

	// Print out our slogan. Literally, "We came, we saw, we conquered."
	Console.setColors(Color.Yellow, Color.LowBlue);
	kprintfln!("Venimus, vidimus, vicimus!  --PittGeeks")();
	Console.setColors(Color.LowGreen, Color.Black);
	kprintf!("--------------------------------------------------------------------------------")();
	Console.resetColors();

	// get the globals from the linker definitions
	printLogLine("Initializing Globals");
	Globals.init();
	printLogSuccess();

	// Make sure the multiboot header is valid
	// and print out memory info, etc
	multiboot.init(magic, addr);

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

	CpuTable.init();

	//pMem.test();

	// boot and initialize the primary CPU
	Cpu.install();

	VESA.init();

	//kprintfln!("Setting lstar, star and SF_MASK...")();

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

	Multiprocessor.initialize();

/*	printLogLine("Initializing HPET");
	if (Timer.init() == ErrorVal.Success)
	{
		printLogSuccess();
	}
	else
	{
		printLogFail();
	}*/

	Keyboard.init();
	//kprintfln!("Keyboards Inited!!!")();

	// Turn general interrupts on, so the computer can deal with errors and faults.
	printLogLine("Initializing Interrupts");
	Cpu.enableInterrupts();
	printLogSuccess();

	printLogLine("Initializing Scheduler");
	if (Scheduler.init() == ErrorVal.Success)
	{
		printLogSuccess();
	}
	else
	{
		printLogFail();
	}

	printLogLine("Starting APs");
	Multiprocessor.startAPs();
	printLogSuccess();

	Scheduler.run();

	// should not return from this

}
