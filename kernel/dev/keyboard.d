module kernel.dev.keyboard;

import kernel.arch.x86_64.cpu;
import kernel.arch.x86_64.ioapic;
import kernel.arch.x86_64.pic;
import kernel.arch.x86_64.idt;
import kernel.arch.x86_64.lapic;

import kernel.arch.locks;

import kernel.environment.scheduler;

import kernel.dev.vga;

import kernel.core.error;

import config;

import user.keycodes;

const int BUFF_SIZE = 1024;

struct Keyboard {
static:

	// soon to be destroyed:
//short [BUFF_SIZE] buff;
int ipos;
int gpos;
	// -----

int bufferLen;
short* buffer;

int* readPointer;
int* writePointer;

kmutex bufferLock;

void depositKey(short c) {
	bufferLock.lock();
	if(((*writePointer) < (bufferLen - 1)) && (((*writePointer) + 1) != (*readPointer))) {
		buffer[(*writePointer)] = c;
		(*writePointer)++;
	} else if((*readPointer) != 0) {
		buffer[(*writePointer)] = c;
		(*writePointer) = 0;
	} else {
		//igonore!
	}
	bufferLock.unlock();
}


void function(ubyte code) downFunc;
void function(ubyte code) upFunc;
void function(char chr) charFunc;

void mapFunctions(void function(ubyte) downProc, void function(ubyte) upProc, void function(char) charProc)
{
	downFunc = downProc;
	upFunc = upProc;
	charFunc = charProc;
}

ErrorVal setBuffer(short* buff, int* readPtr, int* writePtr, int buffLen)
{
	readPointer = readPtr;
	writePointer = writePtr;
	buffer = buff;

	// do this last
	bufferLen = buffLen;

	return ErrorVal.Success;
}

void unsetBuffer()
{
	// this will stop the usage of the keyboard buffer
	bufferLock.lock();
	bufferLen = 0;
	bufferLock.unlock();
}

void init() {
	//IOAPIC.setRedirectionTableEntry(1,1, 0xFF, IOAPICInterruptType.Unmasked,
	//								IOAPICTriggerMode.EdgeTriggered,
	//								IOAPICInputPinPolarity.HighActive,
	//								IOAPICDestinationMode.Physical,
	//								IOAPICDeliveryMode.ExtINT,
	//									35);

	// already done, IO APIC has this irq mapped...
	// simply unmask when ready

	ubyte mode;

	// clear output buffer
	ubyte status;

	status = Cpu.ioIn!(ubyte, "64h")();

	while((status & 0x1) == 1) {
		Cpu.ioIn!(ubyte, "60h")();
		status = Cpu.ioIn!(ubyte, "64h")();
	}

	ubyte ack;

	// tell the controller we are going to set the command byte
	Cpu.ioOut!(byte, "64h")(0x60);

	// get ack?
	ack = 0;

//	kdebugfln!(DEBUG_KBD, "Keyboard: Enable Command Byte")();

	// write the command byte to enable keyboard interrupts without translation
	Cpu.ioOut!(byte, "60h")(0x01);

	// get ack?
	ack = 0;

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

	// attempt to find the scancode in use

	//kdebugfln!(DEBUG_KBD, "Keyboard: Scancode mode: {}")(mode);

	//kdebugfln!(DEBUG_KBD, "Keyboard: About to set scancode")();

	// set scan code set (set 2)
	//Cpu.ioOut!(ubyte, "64h")(0xF0);
	//status = Cpu.ioIn!(ubyte, "60h")();
	//Cpu.ioOut!(ubyte, "60h")(0x01);
	//status = Cpu.ioIn!(ubyte, "60h")();


	//kdebugfln!(DEBUG_KBD, "Keyboard: About to unmask the IRQ")();

	// unmask!
	//PIC.EOI(1);
	Interrupts.setCustomHandler(34, &interruptDriver);
	IOAPIC.unmaskIRQ(1);

	//kdebugfln!(DEBUG_KBD, "Keyboard: IRQ umasked")();
	//Cpu.ioOut!(ubyte, "64h")(0xF0);
	//Cpu.ioOut!(ubyte, "60h")(0x0);

	// write to P2
	// NOTE: a write with bit 0 set to 0 WILL RESET THE CPU!!
	//ubyte newP2 = (1 << 0) | (1 << 4) | (1 << 1); // do not reset CPU, keep Gate-A20 enabled (sigh), and assert IRQ1
	//Cpu.ioOut!(ubyte, "64h")(0xD1);
	//Cpu.ioOut!(ubyte, "60h")(newP2);

	//Cpu.ioOut!(ubyte, "64h")(0xD0);
	//P2 = Cpu.ioIn!(ubyte, "60h")();
	//kdebugfln!(DEBUG_KBD, "Keyboard - P2 (after activating IRQ1): {}")(P2);

	upState = false;
	makeState = 0;
	ipos = 0;
	gpos = 0;

	readPointer = &gpos;
	writePointer = &ipos;

	bufferLen = 0;
	buffer = null; //&buff[0];
}

static bool keyState[256];

bool upState = false;
int makeState = 0;

// an interrupt driven approach
void interruptDriver(InterruptStack* s) {
	common();

	PIC.EOI(1);
	LocalAPIC.EOI();
}

// a polling keyboard driver
void pollingDriver() {

	// the status register bit 0 will indicate something in the keyboard buffer
	// when this is true, we can interpret what is in this buffer

	ubyte status;

		for(;;) {

		status = Cpu.ioIn!(ubyte, "64h")();

		if (status  & 0x1) {
			common();
		}

	}
}

private void common() {
	// output buffer full
	ubyte data = Cpu.ioIn!(ubyte, "60h")();

	short key = 0;

	if (data == 0xe0) {
		// it is a make code from the extended set
		makeState = 1;
	}
	else if (data == 0xf0) {
		// it is a break code
		upState = true;
	}
	else {
		if (makeState == 0) {
			key = set2translate[data];
		}
		else if (makeState == 1) {
			key = set2translateExtra[data];
		}

		if (upState) {
			key = -key;
		}

		depositKey(key);
		//keyState[data] = !upState;
		//ubyte translated = translateScancode(data);

		//if (translated != 0 && !upState)
		//{
			// printable character
			// kprintf!("{}{}", false)(cast(char)translated, charFunc);
			//if (charFunc) { charFunc(cast(char)translated); } //else { kprintf!("{}", false)(translated); }
			//deposit(translated);
		//}

		//if (upState) {
			//kprintf!("{} = {}")(data, 0);
		//	if (upFunc) { upFunc(data); }
		//} else {
			//kprintf!("{} = {}")(data, 1);
		//	if (downFunc) { downFunc(data); }
		//}
		makeState = 0;
		upState = false;
	}
}

// should be set up for scan code set 2

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

short set2translate[256] = [
	0x1c: Key.A,
	0x32: Key.B,
	0x21: Key.C,
	0x23: Key.D,
	0x24: Key.E,
	0x2B: Key.F,
	0x34: Key.G,
	0x33: Key.H,
	0x43: Key.I,
	0x3B: Key.J,
	0x42: Key.K,
	0x4B: Key.L,
	0x3A: Key.M,
	0x31: Key.N,
	0x44: Key.O,
	0x4D: Key.P,
	0x15: Key.Q,
	0x2D: Key.R,
	0x1B: Key.S,
	0x2C: Key.T,
	0x3C: Key.U,
	0x2A: Key.V,
	0x1D: Key.W,
	0x22: Key.X,
	0x35: Key.Y,
	0x1A: Key.Z,
	0x45: Key.Num0,
	0x16: Key.Num1,
	0x1E: Key.Num2,
	0x26: Key.Num3,
	0x25: Key.Num4,
	0x2E: Key.Num5,
	0x36: Key.Num6,
	0x3D: Key.Num7,
	0x3E: Key.Num8,
	0x46: Key.Num9,
	0x0E: Key.Quote,
	0x4E: Key.Minus,
	0x55: Key.Equals,
	0x5D: Key.Slash,
	0x66: Key.Backspace,
	0x29: Key.Space,
	0x0D: Key.Tab,
	0x58: Key.Capslock,
	0x12: Key.LeftShift,
	0x14: Key.LeftControl,
	0x11: Key.LeftAlt,
	0x59: Key.RightShift,
	0x5A: Key.Return,
	0x76: Key.Escape,
	0x05: Key.F1,
	0x06: Key.F2,
	0x04: Key.F3,
	0x0C: Key.F4,
	0x03: Key.F5,
	0x0B: Key.F6,
	0x83: Key.F7,
	0x0A: Key.F8,
	0x01: Key.F9,
	0x09: Key.F10,
	0x78: Key.F11,
	0x07: Key.F12,
	0x7E: Key.ScrollLock,
	0x54: Key.LeftBracket,
	0x77: Key.NumLock,
	0x7C: Key.KeypadAsterisk,
	0x7B: Key.KeypadMinus,
	0x79: Key.KeypadPlus,
	0x71: Key.KeypadPeriod,
	0x70: Key.Keypad0,
	0x69: Key.Keypad1,
	0x72: Key.Keypad2,
	0x7A: Key.Keypad3,
	0x6B: Key.Keypad4,
	0x73: Key.Keypad5,
	0x74: Key.Keypad6,
	0x6C: Key.Keypad7,
	0x75: Key.Keypad8,
	0x7D: Key.Keypad9,
	0x5B: Key.RightBracket,
	0x4c: Key.Semicolon,
	0x52: Key.Apostrophe,
	0x41: Key.Comma,
	0x49: Key.Period,
	0x4A: Key.Backslash
];

short set2translateExtra[256] = [
	0x1f: Key.LeftMeta,
	0x14: Key.RightControl,
	0x27: Key.RightMeta,
	0x11: Key.RightAlt,
	0x2f: Key.Application,
	0x70: Key.Insert,
	0x6c: Key.Home,
	0x7d: Key.PageUp,
	0x71: Key.Delete,
	0x69: Key.End,
	0x7a: Key.PageDown,
	0x75: Key.Up,
	0x6b: Key.Left,
	0x72: Key.Down,
	0x74: Key.Right,
	0x4a: Key.KeypadBackslash,
	0x5a: Key.KeypadReturn,

	0x4d: Key.Next,
	0x15: Key.Previous,
	0x3b: Key.Stop,
	0x34: Key.Play,
	0x23: Key.Mute,
	0x32: Key.VolumeUp,
	0x21: Key.VolumeDown,
	0x50: Key.Media,
	0x48: Key.EMail,
	0x2b: Key.Calculator,
	0x40: Key.Computer,
	0x10: Key.WebSearch,
	0x3a: Key.WebHome,
	0x38: Key.WebBack,
	0x30: Key.WebForward,
	0x28: Key.WebStop,
	0x20: Key.WebRefresh,
	0x18: Key.WebFavorites
];

ubyte translateScancode(ubyte scanCode) {
	// keyboard scancodes are ordered by their position on the keyboard

	// check for shift state
	if (keyState[0x12] || keyState[0x59]) {
		return translateShift[scanCode];
	}

	return translate[scanCode];
}

}
