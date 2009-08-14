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
import kernel.arch.x86_64.core.paging;

// To return error values
import kernel.core.error;
import kernel.core.log;
import kernel.core.kprintf;

// For heap allocation
import kernel.mem.heap;

private {
	extern(C) {
		extern ubyte stack;
	}
}

struct Cpu
{
static:
public:

	// This module will conform to the interface
	ErrorVal initialize() {

		Paging.install();
		printToLog("Enabling Paging", ErrorVal.Success);

		GDT.install();
		printToLog("Enabling GDT", ErrorVal.Success);
		TSS.install();
		printToLog("Enabling TSS", ErrorVal.Success);
		IDT.install();
		printToLog("Enabling IDT", ErrorVal.Success);

		installStack();
		printToLog("Installed Stack", ErrorVal.Success);

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

	template ioInMixinB(char[] port) {
		const char[] ioInMixinB = `
		asm {
			naked;
			in AL, ` ~ port ~ `;
			ret;
		}`;
	}

	template ioInMixinW(char[] port) {
		const char[] ioInMixinW = `
		asm {
			naked;
			in AX, ` ~ port ~ `;
			ret;
		}`;
	}

	template ioInMixinL(char[] port) {
		const char[] ioInMixinL = `
		asm {
			naked;
			in EAX, ` ~ port ~ `;
			ret;
		}`;
	}


	T ioIn(T, char[] port)() {
		static if (is(T == ubyte) || is(T == byte)) {
			mixin(ioInMixinB!(port));
		}
		else static if (is(T == ushort) || is(T == short)) {
			mixin(ioInMixinW!(port));
		}
		else static if (is(T == uint) || is(T == int)) {
			mixin(ioInMixinL!(port));
		}
		else {
			static assert (false, "Cannot determine data type.");
		}
	}

	void writeMSR(uint MSR, ulong value) {
		uint hi, lo;
		lo = value & 0xFFFFFFFF;
		hi = value >> 32UL;

		asm {
			// move the MSR index to ECX
			// also move the perspective registers
			// HI -> EDX
			// LO -> EAX
			mov EDX, hi;
			mov EAX, lo;
			mov ECX, MSR;
			wrmsr;
		}
	}

	ulong readMSR(uint MSR) {
		ulong ret;
		ulong hi;
		ulong lo;

		asm {
			// move the MSR index to ECX
			mov ECX, MSR;
			
			// read MSR
			rdmsr;

			// EDX -> hi, EAX -> lo
			mov hi, EDX;
			mov lo, EAX;
		}

		ret = hi;
		ret <<= 32;
		ret |= lo;

		return ret;
	}

private:

	// Will create and install a new kernel stack
	// Note: You have to preserve the current stack
	ErrorVal installStack() {
		ubyte* stackSpace = cast(ubyte*)Heap.allocPage();
		ubyte* currentStack = cast(ubyte*)(&stack-4096);

		kprintfln!("currentStack: {x} stackSpace: {x}")(currentStack, stackSpace);
		
		stackSpace[0..4096] = currentStack[0..4096];

		asm {
			// Retrieve stack pointer, place in RAX
			mov RAX, RSP;

			// Get the page offset
			and RAX, 0xFFF;

			// Add this to the stackspace pointer
			add RAX, stackSpace;

			// Set stack pointer
			mov RSP, RAX;
		}

		return ErrorVal.Success;
	}
}
