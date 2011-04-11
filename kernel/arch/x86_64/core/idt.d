/*
 * idt.d
 *
 * The architecture code to implement an interface to the
 * IDT (Interrupt Descriptor Table)
 *
 */

module kernel.arch.x86_64.core.idt;

import kernel.arch.x86_64.core.descriptor;

import user.util;	// For BitField!()
import kernel.core.error;	// For ErrorVal so errors can be indicated
import kernel.core.kprintf;	// For printing the stack dump

// This structure represents the appearance of the stack
// upon receiving an interrupt on this architecture.
struct InterruptStack {
	// Registers
	ulong r15, r14, r13, r12, r11, r10, r9, r8;
	ulong rbp, rdi, rsi, rdx, rcx, rbx, rax;

	// Data pushed by the isr
	ulong intNumber, errorCode;

	// Pushed by the processor
	ulong rip, cs, rflags, rsp, ss;

	// This function will dump the stack information to
	// the screen. Useful for debugging.
	void dump() {
		kprintfln!("Stack Dump:")();
		kprintfln!("r15:{x}|r14:{x}|r13:{x}|r12:{x}|r11:{x}")(r15,r14,r13,r12,r11);
		kprintfln!("r10:{x}| r9:{x}| r8:{x}|rbp:{x}|rdi:{x}")(r10,r9,r8,rbp,rdi);
		kprintfln!("rsi:{x}|rdx:{x}|rcx:{x}|rbx:{x}|rax:{x}")(rsi,rdx,rcx,rbx,rax);
		kprintfln!(" ss:{x}|rsp:{x}| cs:{x}")(ss,rsp,cs);
	}
}

struct IDT {
static:
public:

	alias void function(InterruptStack*) InterruptHandler;

	// -- Functions to initialize the interrupt table -- //

	ErrorVal initialize() {
		// Initialize the IDT base structure that will be
		// loaded via LIDT
		idtBase.limit = (InterruptGateDescriptor.sizeof * entries.length) - 1;
		idtBase.base = cast(ulong)entries.ptr;

		// Initialize the IDT entries to default values
		// They will be the equivalent of this function call:
		//   setInterruptGate(0, &isr0);
		// But done across the entire array
		mixin(generateIDT!(40));

		// Now, set the IDT entries that differ from the norm
		setSystemGate(3, &isr3, StackType.Debug);
		setInterruptGate(8, &isrIgnore);

		return ErrorVal.Success;
	}

	ErrorVal install() {
		asm {
			lidt [idtBase];
		}
		return ErrorVal.Success;
	}


	// -- Stack Types -- //


	enum StackType : uint {
		RegisterStack,
		StackFault,
		DoubleFault,
		NMI,
		Debug,
		MCE
	}

	// -- Known Interrupt Types -- //

	enum InterruptType : uint {
		DivisionByZero,
		Debug,
		NMI,
		Breakpoint,
		INTO,
		OutOfBounds,
		InvalidOpcode,
		NoCoprocessor,
		DoubleFault,
		CoprocessorSegmentOverrun,
		BadTSS,
		SegmentNotPresent,
		StackFault,
		GeneralProtectionFault,
		PageFault,
		UnknownInterrupt,
		CoprocessorFault,
		AlignmentCheck,
		MachineCheck,
		Syscall = 128,
	}

	// -- Table Functions -- //


	// The following functions define entries within the table, where
	// num is the index of the entry to set.
	void setInterruptGate(uint num, void* funcPtr, uint ist = StackType.RegisterStack) {
		setGate(num, SystemSegmentType.InterruptGate, cast(ulong)funcPtr, 0, ist);
	}

	void setSystemGate(uint num, void* funcPtr, uint ist = StackType.RegisterStack) {
		setGate(num, SystemSegmentType.InterruptGate, cast(ulong)funcPtr, 3, ist);
	}

	void assignHandler(InterruptHandler func, uint vector) {
		handlers[vector] = func;
	}


private:


	// -- IDT Table -- //


	// This, like GDT, is the base data to be loaded via LIDT
	align (1) struct IDTBase {
		ushort	limit;
		ulong	base;
	}

	// This is the value we will set via LIDT
	IDTBase idtBase;

	// This is the descriptor for the table
	align(1) struct InterruptGateDescriptor {
		ushort targetLo;
		ushort segment;
		ushort flags;
		ushort targetMid;
		uint targetHi;
		uint reserved = 0;

		mixin(Bitfield!(flags, "ist", 3, "zero0", 5, "type", 4, "zero1", 1, "dpl", 2, "p", 1));
	}

	// Compile time check for structure sanctity
	static assert(InterruptGateDescriptor.sizeof == 16);

	// The actual table
	InterruptGateDescriptor[256] entries;


	// -- Common Structures -- //


	// -- Table Mutators -- //


	// The generic setGate function
	void setGate(uint num, SystemSegmentType gateType, ulong funcPtr, uint dplFlags, uint istFlags) {
		with(entries[num]) {
			targetLo = funcPtr & 0xffff;
			segment = 0x10;	// It will use CS_KERNEL (entry 2)
			ist = istFlags;
			p = 1;
			dpl = dplFlags;
			type = cast(uint)gateType;
			targetMid = (funcPtr >> 16) & 0xffff;
			targetHi = (funcPtr >> 32);
		}
	}


	// -- Template Foo -- //

	// This template generates (for initialize()) the IDT table
	// with default values for all interrupts

	template generateIDT(uint numberISRs, uint idx = 0) {
		static if (numberISRs == idx) {
			const char[] generateIDT = ``;
		}
		else {
			const char[] generateIDT = `
				setInterruptGate(` ~ idx.stringof ~ `, &isr` ~ idx.stringof[0..$-1] ~ `);
			` ~ generateIDT!(numberISRs,idx+1);
		}
	}

	// This template generates a code stub for an ISR

	template generateISR(uint num, bool needDummyError = true) {
		const char[] generateISR = `
			void isr` ~ num.stringof[0..$-1] ~ `() {
				asm {
					naked; ` ~
					(needDummyError ? `pushq 0;` : ``) ~
					`pushq ` ~ num.stringof ~ `;` ~
					`jmp isr_common;` ~
						`
				}
			}
		`;
	}

	template generateISRs(uint start, uint end, bool needDummyError = true) {
		static if (start > end) {
			const char[] generateISRs = ``;
		}
		else {
			const char[] generateISRs = generateISR!(start, needDummyError)
				~ generateISRs!(start+1,end,needDummyError);
		}
	}


	// -- The Interrupt Service Routine Stubs -- //

	mixin(generateISR!(0));
	mixin(generateISR!(1));
	mixin(generateISR!(2));
	mixin(generateISR!(3));
	mixin(generateISR!(4));
	mixin(generateISR!(5));
	mixin(generateISR!(6));
	mixin(generateISR!(7));
	mixin(generateISR!(8, false));
	mixin(generateISR!(9));
	mixin(generateISR!(10, false));
	mixin(generateISR!(11, false));
	mixin(generateISR!(12, false));
	mixin(generateISR!(13, false));
	mixin(generateISR!(14, false));
	mixin(generateISRs!(15,39));

	void isrIgnore() {
		asm {
			naked;
			nop;
			nop;
			nop;
			iretq;
		}
	}

	InterruptHandler[256] handlers;

	void dispatch(InterruptStack* stack) {
		if (handlers[stack.intNumber] !is null) {
			handlers[stack.intNumber](stack);
			return;
		}
//		kprintfln!("Interrupt: {} @ {x}")(stack.intNumber, stack.rip);

		// common interrupt handling
	}

	extern(C) void isr_common() {

		// ISR routine has pushed either one or two values to the stack
		// the stack will contain a few things pushed by hardware and then
		// these two values

		// Before an IRET can be issued, the first two values must be popped

		asm {
			naked;

			// Save context

			pushq RAX;
			pushq RBX;
			pushq RCX;
			pushq RDX;
			pushq RSI;
			pushq RDI;
			pushq RBP;
			pushq R8;
			pushq R9;
			pushq R10;
			pushq R11;
			pushq R12;
			pushq R13;
			pushq R14;
			pushq R15;

			// Run dispatcher
			mov RDI, RSP;
			call dispatch;

			// Restore context

			popq R15;
			popq R14;
			popq R13;
			popq R12;
			popq R11;
			popq R10;
			popq R9;
			popq R8;
			popq RBP;
			popq RDI;
			popq RSI;
			popq RDX;
			popq RCX;
			popq RBX;
			popq RAX;

			add RSP, 16;
			iretq;
		}
	}
}
