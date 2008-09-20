// idt.d - all the idt goodness you can handle
module kernel.idt;



import kernel.vga;
static import gdt = kernel.gdt;

import kernel.core.util;

import kernel.mem.vmem;

alias gdt.IntGateDesc64 IDTEntry;

public align(1) struct IDTPtr
{
	ushort limit;
	ulong base;
}

public extern(C) IDTPtr idtp;

public enum StackType : uint
{
	StackFault = 1,
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

public void setGate(uint num, gdt.SysSegType64 gateType, ulong funcPtr, uint dplFlags, uint istFlags)
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

void setIntGate(uint num, void* funcPtr, uint ist = 0)
{
	setGate(num, gdt.SysSegType64.IntGate, cast(ulong)funcPtr, 0, ist);
}

void setSysGate(uint num, void* funcPtr, uint ist = 0)
{
	setGate(num, gdt.SysSegType64.IntGate, cast(ulong)funcPtr, 3, ist);
}

void install()
{
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
	setIntGate(8, &isr8, StackType.DoubleFault);
	setIntGate(9, &isr9);
	setIntGate(10, &isr10);
	setIntGate(11, &isr11);
	setIntGate(12, &isr12, StackType.StackFault);
	setIntGate(13, &isr13);
	setIntGate(14, &isr14);
	setIntGate(15, &isr15);
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
	setSysGate(0x80, &isr128);

	asm { "lidt (idtp)"; }
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
			(needDummyError ? "`pushq $0`;" : "") ~
			"`pushq $" ~ num.stringof ~ "`;
			`jmp isr_common`;
		}
	}";
}

mixin(ISR!(0));
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
mixin(ISR!(128));

extern(C) void isr_common()
{
	asm
	{
		naked;
		"pushq %%rax";
		"pushq %%rbx";
		"pushq %%rcx";
		"pushq %%rdx";
		"pushq %%rsi";
		"pushq %%rdi";
		"pushq %%rbp";
		"pushq %%r8";
		"pushq %%r9";
		"pushq %%r10";
		"pushq %%r11";
		"pushq %%r12";
		"pushq %%r13";
		"pushq %%r14";
		"pushq %%r15";

		// we don't have to push %rsp, %rip and flags; they are pushed
		// automatically on an interrupt

		"mov %%rsp, %%rdi";
		"call faultHandler";

		"popq %%r15";
		"popq %%r14";
		"popq %%r13";
		"popq %%r12";
		"popq %%r11";
		"popq %%r10";
		"popq %%r9";
		"popq %%r8";
		"popq %%rbp";
		"popq %%rdi";
		"popq %%rsi";
		"popq %%rdx";
		"popq %%rcx";
		"popq %%rbx";
		"popq %%rax";
		
		// A haiku
		// We need to print a stack trace
		// I hate a-s-m
		// This is a job for Jarrett

		// Cleans up the pushed error code and pushed ISR num
		"add $16, %%rsp";

		"iretq";         /* pops 5 things in order: rIP, CS, rFLAGS, rSP, and SS */
	}
}

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

/* This defines what the stack looks like after an ISR was running */
private align(1) struct interrupt_stack
{	
	// registers we pushed
	long r15, r14, r13,	r12, r11, r10, r9, r8, rbp, rdi, rsi, rdx, rcx, rbx, rax;

	// data, pushed by isr
	long int_no, err_code;

	// pushed automatically by the processor
	long rip, cs, rflags, rsp, ss;
}

alias void function(interrupt_stack*) InterruptHandler;

private InterruptHandler[256] InterruptHandlers;

public void ignoreHandler(interrupt_stack* stak) 
{
}


void setCustomHandler(size_t i, InterruptHandler h, int ist = -1)
{
	assert(i < InterruptHandlers.length, "Invalid handler index");

	InterruptHandlers[i] = h;
	
	if(ist >= 0)
		Entries[i].ist = ist;
}

void stack_dump(interrupt_stack* r) {
	kdebugfln!(DEBUG_INTERRUPTS, "r15: 0x{x} / r14: 0x{x} / r13: 0x{x} / r12: 0x{x} / r11: 0x{x}")
			(r.r15, r.r14, r.r13, r.r12, r.r11);

	kdebugfln!(DEBUG_INTERRUPTS, "r10: 0x{x} / r9: 0x{x} / r8: 0x{x} / rbp: 0x{x} / rdi: 0x{x}")
			(r.r10, r.r9, r.r8, r.rbp, r.rdi);

	kdebugfln!(DEBUG_INTERRUPTS, "rsi: 0x{x} / rdx: 0x{x} / rcx: 0x{x} / rbx: 0x{x} / rax: 0x{x}")
			(r.rsi, r.rdx, r.rcx, r.rbx, r.rax);

	kdebugfln!(DEBUG_INTERRUPTS, "ss: 0x{x} / rsp: 0x{x} / cs: 0x{x}")(r.ss, r.rsp, r.cs);
}

/* All of our Exception handling Interrupt Service Routines will
*  point to this function. This will tell us what exception has
*  happened! Right now, we simply halt the system by hitting an
*  endless loop. All ISRs disable interrupts while they are being
*  serviced as a 'locking' mechanism to prevent an IRQ from
*  happening and messing up kernel data structures */

extern(C) void faultHandler(interrupt_stack* r)
{
	if(InterruptHandlers[r.int_no])
	{
		InterruptHandlers[r.int_no](r);
		return;
	}

	if(r.int_no < 32) {
		kdebugfln!(DEBUG_INTERRUPTS, "{}. Code = {}, IP = {x}")(exceptionMessages[r.int_no], r.err_code, r.rip);
		kdebugfln!(DEBUG_INTERRUPTS, "Stack dump:")();
		stack_dump(r);
	} else {
		kdebugfln!(DEBUG_INTERRUPTS, "Unknown exception {}.")(r.int_no);
	}

	asm{hlt;}
}
