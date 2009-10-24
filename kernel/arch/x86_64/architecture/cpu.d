/*
 * cpu.d
 *
 * This module defines the interface for speaking to the Cpu
 *
 */

module architecture.cpu;

// Import Arch Modules
import kernel.arch.x86_64.core.gdt;
import kernel.arch.x86_64.core.tss;
import kernel.arch.x86_64.core.idt;
import kernel.arch.x86_64.core.paging;
import kernel.arch.x86_64.core.lapic;

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

//		Paging.install();
//		printToLog("Cpu: Enabling Paging", ErrorVal.Success);

		GDT.install();
		printToLog("Cpu: Enabling GDT", ErrorVal.Success);
		TSS.install();
		printToLog("Cpu: Enabling TSS", ErrorVal.Success);
		IDT.install();
		printToLog("Cpu: Enabling IDT", ErrorVal.Success);

		installStack();
		printToLog("Cpu: Installed Stack", ErrorVal.Success);

		asm {
			sti;
		}
		printToLog("Cpu: Enabled Interrupts", ErrorVal.Success);

		return ErrorVal.Success;
	}

	uint identifier() {
		return LocalAPIC.identifier;
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
			mov DX, ` ~ port ~ `;
			out DX, AX;
		}`;
	}

	template ioOutMixinL(char[] port) {
		const char[] ioOutMixinL = `
		asm {
			mov EAX, data;
			mov EDX, ` ~ port ~ `;
			out DX, EAX;
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
			mov R15, hi;
			mov R14, lo;
			mov R13, MSR;

			mov RDX, R15;
			mov RAX, R14;
			mov RCX, R13;
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

	void enableInterrupts() {
		asm {
			sti;
		}
	}

	void disableInterrupts() {
		asm {
			cli;
		}
	}

	// Will create and install a new kernel stack
	// Note: You have to preserve the current stack
	ErrorVal installStack() {
		ubyte* stackSpace = cast(ubyte*)Heap.allocPage();
		ubyte* currentStack = cast(ubyte*)(&stack-4096);

		//kprintfln!("currentStack: {x} stackSpace: {x}")(currentStack, stackSpace);
		
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
