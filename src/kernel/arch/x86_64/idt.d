// idt.d - all the idt goodness you can handle
module kernel.arch.x86_64.idt;

import kernel.arch.x86_64.descriptors;

import kernel.core.error;
import kernel.dev.vga;

import kernel.core.util;

import kernel.arch.x86_64.context;

import kernel.arch.x86_64.vmem;

extern (D) void schedule();

alias IntGateDesc64 IDTEntry;

public align(1) struct IDTPtr
{
	ushort limit;
	ulong base;
}

public extern(C) IDTPtr idtp;

/* This defines what the stack looks like after an ISR was running */
align(1) struct InterruptStack
{
	// registers we pushed
	long r15, r14, r13,	r12, r11, r10, r9, r8, rbp, rdi, rsi, rdx, rcx, rbx, rax;

	// data, pushed by isr
	long int_no, err_code;

	// pushed automatically by the processor
	long rip, cs, rflags, rsp, ss;

	void dump()
	{
		kprintfln!("r15: 0x{x} / r14: 0x{x} / r13: 0x{x} / r12: 0x{x} / r11: 0x{x}",false)
			(r15, r14, r13, r12, r11);

		kprintfln!("r10: 0x{x} / r9: 0x{x} / r8: 0x{x} / rbp: 0x{x} / rdi: 0x{x}",false)
			(r10, r9, r8, rbp, rdi);

		kprintfln!("rsi: 0x{x} / rdx: 0x{x} / rcx: 0x{x} / rbx: 0x{x} / rax: 0x{x}",false)
			(rsi, rdx, rcx, rbx, rax);

		kprintfln!("ss: 0x{x} / rsp: 0x{x} / cs: 0x{x}",false)(ss, rsp, cs);
	}

	long getErrorCode()
	{
		return err_code;
	}
}

alias void function(InterruptStack* stack) InterruptHandler;

struct Interrupts
{

static:
private:

// vector of interrupt handling routines
InterruptHandler[256] InterruptHandlers;

void function() scheduleFunction;

public enum StackType : uint
{
	RegisterStack = 0,
	StackFault,
	DoubleFault,
	NMI,
	Debug,
	MCE
}

/* Declare an IDT of 256 entries. Although we will only use the
*  first 32 entries in this tutorial, the rest exists as a bit
*  of a trap. If any undefined IDT entry is hit, it normally
*  will cause an "Unhandled Interrupt" exception. Any descriptor
*  for which the 'presence' bit is cleared (0) will generate an
*  "Unhandled Interrupt" exception */
IDTEntry[256] Entries;

public void setGate(uint num, SysSegType64 gateType, ulong funcPtr, uint dplFlags, uint istFlags)
{
	with(Entries[num])
	{
		target_lo = funcPtr & 0xFFFF;
		segment = 0x10;
		ist = istFlags;
		p = 1;
		dpl = dplFlags;
		type = cast(uint)gateType;
		target_mid = (funcPtr >> 16) & 0xFFFF;
		target_hi = funcPtr >> 32;
	}
}

void setIntGate(uint num, void* funcPtr, uint ist = StackType.RegisterStack)
{
	setGate(num, SysSegType64.IntGate, cast(ulong)funcPtr, 0, ist);
}


void setSysGate(uint num, void* funcPtr, uint ist = StackType.RegisterStack)
{
	setGate(num, SysSegType64.IntGate, cast(ulong)funcPtr, 3, ist);
}

public void install(void function() scheduleFunc)
{
	scheduleFunction = scheduleFunc;

	idtp.limit = (IDTEntry.sizeof * Entries.length) - 1;
	idtp.base = cast(ulong)Entries.ptr;

	setIntGate(0, &isr0);
	setIntGate(1, &isr1, StackType.Debug);
	setIntGate(2, &isr2, StackType.NMI);
	setSysGate(3, &isr3, StackType.Debug);
	setSysGate(4, &isr4);
	setIntGate(5, &isr5);
	setIntGate(6, &isr6);
	setIntGate(7, &isr7);
	// XXX : I ignore this right now, because the PIC still fires INT 8 for IRQ 0... i need to know how to get around this.
	//     : We should not ignore this.  We should also not double fault.  Ever.
	//setIntGate(8, &isr8, StackType.DoubleFault);
	setIntGate(8, &isrIgnore, 0);
	setIntGate(9, &isr9);
	setIntGate(10, &isr10);
	setIntGate(11, &isr11);
	setIntGate(12, &isr12, StackType.StackFault);
	setIntGate(13, &isr13);
	setIntGate(14, &isr14);
	setIntGate(15, &isrIgnore, 0);
	setIntGate(16, &isr16);
	setIntGate(17, &isr17);
	setIntGate(18, &isr18, StackType.MCE);
	setIntGate(19, &isr19);
	setIntGate(20, &isr20);
	setIntGate(21, &isr21);
	setIntGate(22, &isr22);
	setIntGate(23, &isr23);
	setIntGate(24, &isr24);
	setIntGate(25, &isr25);
	setIntGate(26, &isr26);
	setIntGate(27, &isr27);
	setIntGate(28, &isr28);
	setIntGate(29, &isr29);
	setIntGate(30, &isr30);
	setIntGate(31, &isr31);
	setIntGate(32, &isr32);
	setIntGate(33, &isr33);
	setIntGate(34, &isr34);
	setIntGate(35, &isr35);
	setIntGate(36, &isr36);
	setIntGate(37, &isr37);
	setIntGate(38, &isr38);
	setIntGate(39, &isr39);
	setIntGate(40, &isr40);
	setIntGate(41, &isr41);
	setIntGate(42, &isr42);
	setIntGate(43, &isr43);
	setIntGate(44, &isr44);
	setIntGate(45, &isr45);
	setIntGate(46, &isr46);
	setIntGate(47, &isr47);
	setIntGate(48, &isr48);
	setIntGate(49, &isr49);
	setSysGate(0x80, &isr128);

	setIDT();

	installStack();
}

public void setIDT()
{
	asm {
		naked;
		lidt [idtp];
		ret;
//		"lidt (idtp)";
//		"retq";
	}
}

public ErrorVal installStack()
{
	// just use the current kernel stack
//	asm {
//		"movq %%rsp, %%rax" ::: "rax";
//		"movq %%rax, %0" :: "o" tss_struct.ist1 : "rax";
//	}

//	kprintfln!("stack ist: {x}")(tss_struct.ist1);

	return ErrorVal.Success;
}

/*
Exception#	Description								Error Code?
0			Division By Zero Exception				No
1			Debug Exception 						No
2			Non Maskable Interrupt Exception 		No
3			Breakpoint Exception 					No
4			Into Detected Overflow Exception 		No
5			Out of Bounds Exception 				No
6			Invalid Opcode Exception 				No
7			No Coprocessor Exception 				No
8			Double Fault Exception 					Yes
9			Coprocessor Segment Overrun Exception	No
10			Bad TSS Exception 						Yes
11			Segment Not Present Exception 			Yes
12			Stack Fault Exception					Yes
13			General Protection Fault Exception		Yes
14			Page Fault Exception 					Yes
15			Unknown Interrupt Exception 			No
16			Coprocessor Fault Exception 			No
17			Alignment Check Exception (486+) 		No
18			Machine Check Exception (Pentium/586+)	No
19 to 31 	Reserved Exceptions						No
*/

template ISR(int num, bool needDummyError = true)
{
	const char[] ISR =
	"extern(C) void isr" ~ num.stringof ~ "()
	{
		asm
		{
			naked; " ~
			(needDummyError ? "pushq 0;" : "") ~
			"pushq " ~ num.stringof ~ ";
			jmp isr_common;
		}
	}";
}

// simply ignore the interrupt
extern(C) void isrIgnore()
{
	asm
	{
		naked;

		iretq;
	}
}

pragma(msg, "hi!");
mixin(ISR!(0));
pragma(msg, "hi!!");
mixin(ISR!(1));
mixin(ISR!(2));
mixin(ISR!(3));
mixin(ISR!(4));
mixin(ISR!(5));
mixin(ISR!(6));
mixin(ISR!(7));
mixin(ISR!(8, false));
mixin(ISR!(9));
mixin(ISR!(10, false));
mixin(ISR!(11, false));
mixin(ISR!(12, false));
mixin(ISR!(13, false));
mixin(ISR!(14, false));
mixin(ISR!(15));
mixin(ISR!(16));
mixin(ISR!(17));
mixin(ISR!(18));
mixin(ISR!(19));
mixin(ISR!(20));
mixin(ISR!(21));
mixin(ISR!(22));
mixin(ISR!(23));
mixin(ISR!(24));
mixin(ISR!(25));
mixin(ISR!(26));
mixin(ISR!(27));
mixin(ISR!(28));
mixin(ISR!(29));
mixin(ISR!(30));
mixin(ISR!(31));
mixin(ISR!(32));
mixin(ISR!(33));
mixin(ISR!(34));
mixin(ISR!(35));
mixin(ISR!(36));
mixin(ISR!(37));
mixin(ISR!(38));
mixin(ISR!(39));
mixin(ISR!(40));
mixin(ISR!(41));
mixin(ISR!(42));
mixin(ISR!(43));
mixin(ISR!(44));
mixin(ISR!(45));
mixin(ISR!(46));
mixin(ISR!(47));
mixin(ISR!(48));
mixin(ISR!(49));
mixin(ISR!(128));

pragma(msg,"doneisr");
enum Type
{
	DivByZero = 0,
	Debug = 1,
	NMI = 2,
	Breakpoint = 3,
	INTO = 4,
	OutOfBounds = 5,
	InvalidOpcode = 6,
	NoCoproc = 7,
	DoubleFault = 8,
	CoprocSegOver = 9,
	BadTSS = 10,
	SegNotPresent = 11,
	StackFault = 12,
	GPF = 13,
	PageFault = 14,
	UnknownInterrupt = 15,
	CoprocFault = 16,
	AlignCheck = 17,
	MachineCheck = 18,
	Syscall = 128
}

private const char[][] exceptionMessages =
[
	"Division By Zero", //0
	"Debug", //1
	"Non Maskable Interrupt", //2
	"Breakpoint Exception", //3
	"Into Detected Overflow Exception", //4
	"Out of Bounds Exception", //5
	"Invalid Opcode Exception", //6
	"No Coprocessor Exception", //7
	"Double Fault Exception", //8
	"Coprocessor Segment Overrun Exception", //9
	"Bad TSS Exception", //10
	"Segment Not Present Exception", //11
	"Stack Fault Exception", //12
	"General Protection Fault Exception", //13
	"Page Fault Exception", //14
	"Unknown Interrupt Exception", //15
	"Coprocessor Fault Exception", //16
	"Alignment Check Exception (486+)", //17
	"Machine Check Exception (Pentium/586+)", //18
	"Reserved", //19
	"Reserved", //20
	"Reserved", //21
	"Reserved", //22
	"Reserved", //23
	"Reserved", //24
	"Reserved", //25
	"Reserved", //26
	"Reserved", //27
	"Reserved", //28
	"Reserved", //29
	"Reserved", //30
	"Reserved", //31
	"SYSCALL" //128
];

public void setCustomHandler(size_t i, InterruptHandler h, int ist = -1)
{
	assert(i < InterruptHandlers.length, "Invalid handler index");

	InterruptHandlers[i] = h;

	if(ist >= 0)
		Entries[i].ist = ist;
}

}

/* All of our Exception handling Interrupt Service Routines will
*  point to this function. This will tell us what exception has
*  happened! Right now, we simply halt the system by hitting an
*  endless loop. All ISRs disable interrupts while they are being
*  serviced as a 'locking' mechanism to prevent an IRQ from
*  happening and messing up kernel data structures */

extern(C) void fault_handler(InterruptStack* r)
{
	if(Interrupts.InterruptHandlers[r.int_no])
	{
		Interrupts.InterruptHandlers[r.int_no](r);
		return;
	}

	if(r.int_no < 32) {
		kprintfln!("{}. Code = {}, IP = {x}", false)(Interrupts.exceptionMessages[r.int_no], r.err_code, r.rip);
		kprintfln!("Stack dump:", false)();
		r.dump();
	} else {
		kprintfln!("Unknown exception {}.", false)(r.int_no);
	}

	for(;;){}
	//asm{
	//	hlt;
	//}
}
pragma(msg, "bleh");
extern(C) void isr_common()
{
	// TSS should have switched to REGISTER_STACK-8
	// (2nd entry, 1st is for saving top of stack)
	// Hardware / ISRn() would have pushed the general
	// stack information to the REGISTER_STACK

	// SS
	// RSP
	// FLAGS
	// CS
	// RIP
	// ERROR CODE
	// INTERRUPT VECTOR #

	asm
	{
		naked;

		// SS, RSP, FLAGS, CS, RIP, ERROR CODE, INT VECTOR
		// so the stack is at 8 bytes per 7 entries

		//"cmpq $0x38, -0x20(%%rsp)";
		//"jne isr_kernel";

		//cmp -0x20[%rsp], 0x38;
		jne isr_kernel;
	}

	//mixin(contextSwitchSave!());

	asm
	{
		//naked;
		// save top of REGISTER_STACK
		// also pass it as the first parameter (%rdi)
		// to the fault handler
		//"movq %%rsp, %%rdi";
		//movq RDI, RSP;
		//"movq %%rsp, %%rax";
		movq RAX, RSP;
		//"movq %%rax, " ~ Itoa!(vMem.REGISTER_STACK_POS) ::: "rax";
		movq [vMem.REGISTER_STACK_POS], RAX;

		// switch to KERNEL_STACK
		//"movq $" ~ Itoa!(vMem.KERNEL_STACK) ~ ", %%rsp";
		movq rsp, vMem.KERNEL_STACK


		// transfer control to the fault handler
		//"call fault_handler";
		call fault_handler;

		// schedule
		//"call *%0" :: "m" Interrupts.scheduleFunction;

		// switch back to REGISTER_STACK
		//"movq " ~ Itoa!(vMem.REGISTER_STACK_POS) ~ ", %%rax" ::: "rax";
		movq rax, [vMem.REGISTER_STACK_POS];

		// go to top of REGISTER_STACK
		//"movq %%rax, %%rsp";
		movq rsp, rax;
	}

	mixin(contextSwitchRestore!());

	asm
	{
		naked;

		// A haiku - saved here for posterity - we now love a-s-m

			// We need to print a stack trace
			// I hate a-s-m
			// This is a job for Jarrett

		// Cleans up the pushed error code and pushed ISR num
		//"add $16, %%rsp";
		add rsp, 16;
		//"iretq";         /* pops 5 things in order: rIP, CS, rFLAGS, rSP, and SS */
		iretq;







		// KERNEL ISR COMMON

		//"isr_kernel:";
isr_kernel:;
	}

	mixin(contextSwitchSave!());

	asm
	{
		//"movq %%rsp, %%rdi";
		//movq rdi, rsp;
		//"call fault_handler";
		call fault_handler;
	}

	mixin(contextSwitchRestore!());

	asm
	{
		//"add $16, %%rsp";
		add rsp, 16;
		//"iretq";
		iretq;
	}
}

pragma(msg, "hey");
