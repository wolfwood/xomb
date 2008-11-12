module kernel.dev.keyboard;

import kernel.arch.x86_64.init;
import kernel.arch.x86_64.ioapic;
import kernel.arch.x86_64.pic;
import kernel.arch.x86_64.idt;
import kernel.arch.x86_64.lapic;

import kernel.dev.vga;

import config;

struct Keyboard {

static:

void init() {

	//PIC.enableIRQ(1);
	
	//IOAPIC.setRedirectionTableEntry(1,1, 0xFF, IOAPICInterruptType.Unmasked, 
	//								IOAPICTriggerMode.EdgeTriggered, 
	//								IOAPICInputPinPolarity.HighActive,
	//								IOAPICDestinationMode.Physical,
	//								IOAPICDeliveryMode.ExtINT,
	//									35);

	// already done, IO APIC has this irq mapped...
	// simply unmask when ready

	ubyte ack;

	// tell the controller we are going to set the command byte	
	Cpu.ioOut!(byte, "64h")(0x60);

	// get ack?
	ack = Cpu.ioIn!(ubyte, "60h")();   
	kprintfln!("ack? {x}")(ack);

	// write the command byte to enable keyboard interrupts
	Cpu.ioOut!(byte, "60h")(0x01);

	// get ack?
	ack = Cpu.ioIn!(ubyte, "60h")();
	kprintfln!("ack? {x}")(ack);

	// enable the keyboard (extra precaution?)
	Cpu.ioOut!(byte, "64h")(0xAE);

	ack = Cpu.ioIn!(ubyte, "60h")();
	kprintfln!("ack? {x}")(ack);

	//ubyte status = Cpu.ioIn!(ubyte, "64h")();
	
	//kdebugfln!(DEBUG_KBD, "Keyboard - Current Status: {}")(status);

	// enable the keyboard (alternate???)
	Cpu.ioOut!(byte, "60h")(0xF4);
	ack = Cpu.ioIn!(ubyte, "60h")();
	kprintfln!("ack? {x}")(ack);

	//status = Cpu.ioIn!(ubyte, "64h")();

	//kdebugfln!(DEBUG_KBD, "Keyboard - Current Status: {}")(status);

	// get the command register from the keyboard controller
	///Cpu.ioOut!(ubyte, "64h")(0x20);
	//ubyte command = Cpu.ioIn!(ubyte, "60h")();

	//kdebugfln!(DEBUG_KBD, "Keyboard - Command Register: {}")(command);

	// read P1 (input port)
	//Cpu.ioOut!(ubyte, "64h")(0xC0);
	//ubyte P1 = Cpu.ioIn!(ubyte, "60h")();
	//kdebugfln!(DEBUG_KBD, "Keyboard - P1: {}")(P1);

	// read P2 (output port)
	//Cpu.ioOut!(ubyte, "64h")(0xD0);
	//ubyte P2 = Cpu.ioIn!(ubyte, "60h")();
	//kdebugfln!(DEBUG_KBD, "Keyboard - P2: {}")(P2);

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

	// unmask!
	PIC.EOI(1);
	IDT.setCustomHandler(34, &interruptDriver);
	IOAPIC.unmaskIRQ(1);

	// write to P2
	// NOTE: a write with bit 0 set to 0 WILL RESET THE CPU!!
	//ubyte newP2 = (1 << 0) | (1 << 4) | (1 << 1); // do not reset CPU, keep Gate-A20 enabled (sigh), and assert IRQ1
	//Cpu.ioOut!(ubyte, "64h")(0xD1);
	//Cpu.ioOut!(ubyte, "60h")(newP2);

	//Cpu.ioOut!(ubyte, "64h")(0xD0);
	//P2 = Cpu.ioIn!(ubyte, "60h")();
	//kdebugfln!(DEBUG_KBD, "Keyboard - P2 (after activating IRQ1): {}")(P2);

	// no more! we have intarups!
	//pollingDriver();

	// we still need to flush the buffer though
	//common()
}

static bool keyState[256];

bool upState = false;

// an interrupt driven approach
void interruptDriver(interrupt_stack*s)
{
	common();

	PIC.EOI(1);
	LocalAPIC.EOI();		
}

// a polling keyboard driver
void pollingDriver()
{

	// the status register bit 0 will indicate something in the keyboard buffer
	// when this is true, we can interpret what is in this buffer

	ubyte status;

	// set scan code set (set 3)
	Cpu.ioOut!(ubyte, "64h")(0xF0);
	status = Cpu.ioIn!(ubyte, "60h")();
	Cpu.ioOut!(ubyte, "60h")(0x03);
	status = Cpu.ioIn!(ubyte, "60h")();

	for(;;) {

		status = Cpu.ioIn!(ubyte, "64h")();

		if (status  & 0x1) { 
			common();
		}
	
	}
}

private void common()
{
//	kprintf!("int", false)();

	//for (;;) 
	{
		//ubyte status = Cpu.ioIn!(ubyte, "64h")();

		//if (!(status & 0x1)) { break; }

		// output buffer full
		ubyte data = Cpu.ioIn!(ubyte, "60h")();

		//if (data == 0x0) { break; }

		if (data == 0xf0)
		{
			// it is an up code
			upState = true;
		}
		else
		{
			keyState[data] = !upState;
			ubyte translated = translateScancode(data);
	
			if (translated != 0 && !upState)
			{
				// printable character
				kprintf!("{}", false)(cast(char)translated);
			}
			if (upState) {
			//kprintf!("{} = {}")(data, 0);
			} else {
			//kprintf!("{} = {}")(data, 1);
			}	
			upState = false;
		}
	}
//	kprintf!("iret",false)();
}

ubyte translate[256] = 
[0,0,0,0,0,0,0,0,0,0,0,0,0,9,96,0,0,0,0,0,0,113,49,0,0,0,122,115,97,119,50,0,0,99
,120,100,101,52,51,0,0,32,118,102,116,114,53,0,0,110,98,104,103,121,54,0,0,0,109
,106,117,55,56,0,0,44,107,105,111,48,57,0,0,46,47,108,59,112,45,0,0,0,39,0,91,61
,0,0,0,0,10,93,0,92,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
,0,0,0,0,0,0,0,0,0,0,0,0];

ubyte translateShift[256] =
[0,0,0,0,0,0,0,0,0,0,0,0,0,9,126,0,0,0,0,0,0,81,33,0,0,0,90,83,65,87,64,0,0,67,
88,68,69,36,35,0,0,32,86,70,84,82,37,0,0,78,66,72,71,89,94,0,0,0,77,74,85,38,42,0
,0,60,75,73,79,41,40,0,0,62,63,76,58,80,95,0,0,0,34,0,123,43,0,0,0,0,10,125,0,124
,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0];

ubyte translateScancode(ubyte scanCode)
{
	// keyboard scancodes are ordered by their position on the keyboard

	// check for shift state
	if (keyState[0x12] || keyState[0x59])
	{
		return translateShift[scanCode];
	}

	return translate[scanCode];	
}

}
