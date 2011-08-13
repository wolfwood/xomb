module architecture.syscall;

import architecture.cpu;

import kernel.core.error;
import kernel.core.util;
import kernel.core.syscall;

import user.syscall;

import kernel.mem.pageallocator;
import architecture.vm;

const ulong FSBASE_MSR = 0xc000_0100;
const ulong GSBASE_MSR = 0xc000_0101;


struct Syscall {
static:

	ErrorVal initialize () {
		// TODO: USE MSR ROUTINES IN kernel.arch.x86_64.init TO SET THESE!!!

		// STAR (MSR: 0xC0000081)
		// [0..31]	: Target EIP address	: During SYSCALL, this is copied into EIP if we were
		//									:   in 32 bit mode
		// [32..47]	: CS, SS Base (CALL)	: During SYSCALL, the contents of this field are copied to
		//									:   the CS register, and the SS register (plus 1000b)
		// [48..63]	: CS, SS Base (RET)		: Ditto, except during SYSRET

		// WHAT DOES THIS MEAN?
		// - SYSRET will set CS (the current code segment) to point to the selector given + 16
		// - This entry better be the code segment
		// - Selectors are given as the ((selector index into GDT) << 3) | (RPL)
		// - RPL: The ring it will change to.  For SYSRET, this would be 3, SYSCALL, 0
		// - SYSRET will set SS (the current stack segment) to the value of CS + 8
		// - This entry better be the data segment
		// - This means you have a DataSegment followed by a CodeSegment in your GDT
		// - You point to the entry BEFORE the DataSegment

		// LSTAR (MSR: 0xC0000082)
		// - simply holds the RIP of the syscall handler

		// SFMASK (MSR: 0xC0000084)
		// [0..31]	: SYSCALL Flag Mask		: Will reset bits in RFLAGS.
		//									: If a bit is 1 here, it will reset the bit in RFLAGS.
		//									: If the bit is 0, nothing will happen

		const ulong STAR_MSR = 0xc000_0081;
		const ulong LSTAR_MSR = 0xc000_0082;
		const ulong SFMASK_MSR = 0xc000_0084;

		const ulong STAR = 0x003b_0010_0000_0000;
		const uint STARHI = STAR >> 32;
		const uint STARLO = STAR & 0xFFFF_FFFF;

		ulong addy = cast(ulong)&syscallHandler;

		// Set the LSTAR register.  This is the address of the system call handling
		// routine.
		Cpu.writeMSR(LSTAR_MSR, addy);

		// Set the STAR register.  This is more stupid segmentation bullshit.
		Cpu.writeMSR(STAR_MSR, STAR);

		// Set the SF_MASK register.  Top should be 0, bottom is our mask,
		// but we're not masking anything (yet).
		Cpu.writeMSR(SFMASK_MSR, 0);

		// stash a syscall stack in GS.Base
		PhysicalAddress stackPtr = PageAllocator.allocPage();
		ulong syscallStack = cast(ulong)VirtualMemory.mapStack(stackPtr) + 4096;

		asm{
			pushq RAX;
			mov RAX, 3;
			shl RAX, 3;
			mov GS, AX;
			popq RAX;
		}

		Cpu.writeMSR(GSBASE_MSR, syscallStack);

		return ErrorVal.Success;
	}
}


// alright, so %rdi, %rsi, %rdx are the registers loaded by NativeSyscall()
//
void syscallHandler() {
	asm {
		naked;

		// XXX: use swapgs rather than rdmsr
		/*
		// save old RSP
		mov R9, RSP;

		// calculate new RSP (uses effective address calculation to get value out of GS segment descriptor without and rdmsr)
		swapgs;
		mov R8, 0;
		lea R8, GS:[R8];

		// new stack
		mov RSP, R8;
		*/

		// save regs used by rdmsr
		mov R8, RAX;
		mov R9, RCX;
		mov R10, RDX;

		// zero RAX higher bits, cuz rdmsr doc doesn't mention if it zeros it
		mov RAX, 0;

		// read the CPU stack address to RDX
		mov ECX, GSBASE_MSR;
		rdmsr;

		shl RDX, 32;
		or RDX, RAX;

		// restore saved registers and stick new stack addr in R8, old stack addr in R9
		mov RAX, R8;
		mov RCX, R9;

		mov R8, RDX;
		mov RDX, R10;
		mov R9, RSP;

		// set new stack
		mov RSP, R8;

		// save old stack info where we can get it
		pushq R9;
		pushq RBP;

		// vars used by syscall
		pushq RCX;
		pushq R11;
		pushq RAX;

		// call dispatcher
		call syscallDispatcher;

		popq RAX;
		popq R11;
		popq RCX;

		// restore stack foo
		popq RBP;
		popq R9;
		mov RSP, R9;

		sysretq;
	}
}

template MakeSyscallDispatchCase(uint idx) {
	static if(!is(SyscallRetTypes[idx] == void))
		const char[] MakeSyscallDispatchCase =
`case ` ~ idx.stringof ~ `:
	return SyscallImplementations.` ~ SyscallName!(idx) ~ `(*(cast(` ~ SyscallRetTypes[idx].stringof ~
	`*)ret), cast(` ~ ArgsStruct!(idx) ~ `*)params);`;
	else
		const char[] MakeSyscallDispatchCase =
`case ` ~ idx.stringof ~ `:
	return SyscallImplementations.` ~ SyscallName!(idx) ~ `(cast(` ~ ArgsStruct!(idx) ~ `*)params);`;
}

template MakeSyscallDispatchList() {
	const char[] MakeSyscallDispatchList =
`switch(ID)
{`
	~ Reduce!(Cat, Map!(MakeSyscallDispatchCase, Range!(SyscallID.max + 1))) ~
`default:
//	kprintfln!("Syscall not supported!")();
}`;
}

extern(C) void syscallDispatcher(ulong ID, void* ret, void* params) {
	// RCX holds the return address for the system call, which is useful
	// for certain system calls (such as fork)

	//void* stackPtr;
	//asm {
	//	"movq %%rsp, %%rax" ::: "rax";
	//	"movq %%rax, %0" :: "o" stackPtr : "rax";
	//}//
	//kprintfln!("Syscall: ID = 0x{x}, ret = 0x{x}, params = 0x{x}")(ID, ret, params);
	mixin(MakeSyscallDispatchList!());
}
