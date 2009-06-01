/*
 * cpu.d
 *
 * This module defines the interface for speaking to the Cpu
 *
 */

module kernel.arch.x86_64.cpu;

// Import Arch Modules
import kernel.arch.x86_64.core.gdt;
import kernel.arch.x86_64.core.tss;
import kernel.arch.x86_64.core.idt;

// To return error values
import kernel.core.error;
import kernel.core.log;
import kernel.core.kprintf;

struct Cpu
{
static:
public:

	// This module will conform to the interface
	ErrorVal initialize() {
		GDT.install();
		printToLog("Enabling GDT", ErrorVal.Success);
		TSS.install();
		printToLog("Enabling TSS", ErrorVal.Success);
		IDT.install();
		printToLog("Enabling IDT", ErrorVal.Success);

		return ErrorVal.Success;
	}

	template ioOutMixinB(char[] port) {
		const char[] ioOutMixinB = `
		asm {
			mov AL, data;
			out ` ~ port ~ `, AL;
		}`;
	}

	template ioOutMixinW(char[] port) {
		const char[] ioOutMixinW = `
		asm {
			mov AX, data;
			out ` ~ port ~ `, AX;
		}`;
	}

	template ioOutMixinL(char[] port) {
		const char[] ioOutMixinL = `
		asm {
			mov EAX, data;
			out ` ~ port ~ `, EAX;
		}`;
	}

	void ioOut(T, char[] port)(int data) {
		//static assert (port[$-1] == 'h', "Cannot reduce port number");

		static if (is(T == ubyte) || is(T == byte)) {
			mixin(ioOutMixinB!(port));
		}
		else static if (is(T == ushort) || is(T == short)) {
			mixin(ioOutMixinW!(port));
		}
		else static if (is(T == uint) || is(T == int)) {
			mixin(ioOutMixinL!(port));
		}
		else {
			static assert (false, "Cannot determine data type.");
		}
	}
}
