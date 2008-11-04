module kernel.dev.keyboard;

import kernel.arch.x86_64.init;
import kernel.arch.x86_64.ioapic;
import kernel.dev.vga;

import config;

void kbd_init() {
	
	IOAPIC.setRedirectionTableEntry(1, 0xFF, IOAPICInterruptType.Unmasked, 
									IOAPICTriggerMode.EdgeTriggered, 
									IOAPICInputPinPolarity.HighActive,
									IOAPICDestinationMode.Physical,
									IOAPICDeliveryMode.ExtINT,
										35);

	// tell the controller we are going to set the command byte	
	Cpu.ioOut!(byte, "64h")(0x60);    

	// write the command byte to enable keyboard interrupts
	Cpu.ioOut!(byte, "60h")(0x01);

	// enable the keyboard (extra precaution?)
	Cpu.ioOut!(byte, "64h")(0xAE);

	ubyte status = Cpu.ioIn!(ubyte, "64h")();
	
	kdebugfln!(DEBUG_KBD, "Keyboard - Current Status: {}")(status);

	// enable the keyboard (alternate???)
	//Cpu.ioOut!(byte, "60h")(0xF4);

	//status = Cpu.ioIn!(ubyte, "64h")();

	//kdebugfln!(DEBUG_KBD, "Keyboard - Current Status: {}")(status);

	// get the command register from the keyboard controller
	Cpu.ioOut!(ubyte, "64h")(0x20);
	ubyte command = Cpu.ioIn!(ubyte, "60h")();

	kdebugfln!(DEBUG_KBD, "Keyboard - Command Register: {}")(command);

	// read P1 (input port)
	Cpu.ioOut!(ubyte, "64h")(0xC0);
	ubyte P1 = Cpu.ioIn!(ubyte, "60h")();
	kdebugfln!(DEBUG_KBD, "Keyboard - P1: {}")(P1);

	// read P2 (output port)
	Cpu.ioOut!(ubyte, "64h")(0xD0);
	ubyte P2 = Cpu.ioIn!(ubyte, "60h")();
	kdebugfln!(DEBUG_KBD, "Keyboard - P2: {}")(P2);

	// schematics of P1
	// ----------------------
	// bit 0 - Keyboard Data In 
	// bit 1 - Mouse Data In
	// bit 2 - Keyboard Power (0: normal, 1: no power)
	// bit 3 - Unused
	// bit 4 - RAM (0: 512KB, 1: 256KB)
	// bit 5 - Manufacturing Jumper (0: installed, 1: not installed) ... With jumper BIOS runs an infinite diagnostic loop.
	// bit 6 - Display (0: CGA, 1: MDA)
	// bit 7 - Keyboard Lock (0: locked, 1: unlocked)
	
	// schematics of P2
	// ----------------------
	// bit 0 - Reset (0: reset CPU, 1: do not reset CPU)
	// bit 1 - A20 (0: line is forced, 1: A20 enabled)
	// bit 2 - Mouse Data
	// bit 3 - Mouse Clock
	// bit 4 - IRQ 1 (0: active, 1: inactive)	// commonly Keyboard IRQ, tells whether or not the IRQ is currently firing
	// bit 5 - IRQ 12 (0: active, 1: inactive)	// commonly Mouse IRQ
	// bit 6 - Keyboard Clock
	// bit 7 - Keyboard Data

	// write to P2
	// NOTE: a write with bit 0 set to 0 WILL RESET THE CPU!!
	ubyte newP2 = (1 << 0) | (1 << 4) | (1 << 1); // do not reset CPU, keep Gate-A20 enabled (sigh), and assert IRQ1
	Cpu.ioOut!(ubyte, "64h")(0xD1);
	Cpu.ioOut!(ubyte, "60h")(newP2);

	Cpu.ioOut!(ubyte, "64h")(0xD0);
	P2 = Cpu.ioIn!(ubyte, "60h")();
	kdebugfln!(DEBUG_KBD, "Keyboard - P2 (after activating IRQ1): {}")(P2);
}
