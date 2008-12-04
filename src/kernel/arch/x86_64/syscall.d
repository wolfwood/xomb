module kernel.arch.x86_64.syscall;


import kernel.dev.vga;

import user.syscall;
import kernel.core.util;
import kernel.arch.x86_64.vmem;
import kernel.arch.x86_64.context;
import kernel.error;

import kernel.core.syscall;


struct Syscall
{

static:

/**
This function declares a handler for system calls. It accepts a pointer to a function (h).
h will be called to fully handle the system call, depending on the register values for the system call.

Params:
	h = A function that will be tied to the system call to handle it.
*/
void setHandler(void* h)
{
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

	ulong addy = cast(ulong)h;
	uint hi = addy >> 32;
	uint lo = addy & 0xFFFFFFFF;

	//kprintfln!("Setting the Handler.")();

	asm
	{
		// Set the LSTAR register.  This is the address of the system call handling
		// routine.
		"movl %0, %%edx\n"
		"movl %1, %%eax\n"
		"movl %2, %%ecx\n" :: "r" hi, "r" lo, "i" LSTAR_MSR : "edx", "eax", "ecx";
		"wrmsr";

		// Set the STAR register.  This is more stupid segmentation bullshit.
		"movl %0, %%edx\n"
		"movl %1, %%eax\n"
		"movl %2, %%ecx" :: "i" STARHI, "i" STARLO, "i" STAR_MSR : "edx", "eax", "ecx";
		"wrmsr";

		// Set the SF_MASK register.  Top should be 0, bottom is our mask,
		// but we're not masking anything (yet).
		"xorl %%eax, %%eax\n"
		"xorl %%edx, %%edx\n"
		"movl %0, %%ecx" :: "i" SFMASK_MSR : "eax", "edx", "ecx";
		"wrmsr";
	}
}

//pragma(msg, "" ~ Itoa!(cast(long)vMem.REGISTER_STACK));

template jumpToUser(char[] stackPtr, char[] address)
{
/*    const char[] jumpToUser = `

    asm{
		naked;

		// place the address into rcx from rdi (the 1st argument)
		"movq %0, %%rcx" :: "m" ` ~ address ~ ` : "rcx";
		"movq %0, %%rsp" :: "m" ` ~ stackPtr ~ `;
		
		// enable IF flag and allow all ports with the IOPL
		// http://en.wikipedia.org/wiki/FLAGS_register_(computing)
		"movq $((1 << 9) | (3 << 12)), %%r11" ::: "r11";

		// perform the SYSRET
		"sysretq";		
	}

    `;
 /*/
	const char[] jumpToUser = `

	asm {

		naked;

		"movq $` ~ Itoa!(vMem.REGISTER_STACK-8) ~ `, %%rsp";

		// go to bottom of register stack
		"popq %%rsp";

	}

	mixin(contextSwitchRestore!());

	asm {

		// get variables from stack
		"addq $16, %%rsp";
		"popq %%rcx";
		"addq $8, %%rsp";
		"popq %%r11";
		"popq %%rax";

		// switch to user stack
		"movq %%rax, %%rsp";

		// go to user
		"sysretq";
	}


	`;
	// */
}



// alright, so %rdi, %rsi, %rdx are the registers loaded by NativeSyscall()
//

void syscallHandler()
{
	asm
	{
		naked;

		// switch to register stack
		// preserve current rsp, somehow
		
		"movq %%rsp, %%rax";
		"movq $" ~ Itoh!(vMem.REGISTER_STACK - 8) ~ ", %%rsp";

		// emulate interrupt stack
		"pushq $((8 << 3) | 3)";	// USER_DS (SS)
		"pushq %%rax";			// STACK
		"pushq %%r11";			// RFLAGS
		"pushq $((9 << 3) | 3)";	// USER_CS
		"pushq %%rcx";			// RIP
		"pushq $0";			// ERROR CODE
		"pushq $0";			// INTERRUPT NUMBER

		// push registers
	}
	
	mixin(contextSwitchSave!());		

	asm 
	{
		// save top of register stack
		"movq %%rsp, %%rax; movq %%rax, " ~ Itoa!(vMem.REGISTER_STACK-8) ::: "rax"; 

		// switch to KERNEL STACK
		"movq $" ~ Itoa!(vMem.KERNEL_STACK) ~ ", %%rsp";

		// call dispatcher
		"callq syscallDispatcher";

		// go to bottom of register stack
		// the stack pointer is the first entry on the register stack
		"movq $" ~ Itoa!(vMem.REGISTER_STACK-8) ~ ", %%rsp";
		"popq %%rsp";
	}
		
	mixin(contextSwitchRestore!());

	asm
	{

		"addq $16, %%rsp"; 

		// -- corresponds to iretq in interrupt handler -- //
		//"iretq";
		// -- corresponds to iretq in interrupt handler -- //
		
		"popq %%rcx";
		"addq $8, %%rsp";
		"popq %%r11";
		"popq %%rax";

		"movq %%rax, %%rsp";

		"sysretq";
	}
}

}












template MakeSyscallDispatchCase(uint idx)
{
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

template MakeSyscallDispatchList()
{
	const char[] MakeSyscallDispatchList =
`switch(ID)
{`
	~ Reduce!(Cat, Map!(MakeSyscallDispatchCase, Range!(SyscallID.max + 1))) ~
`default:
	kprintfln!("Syscall not supported!")();
}`;
}



extern(C) void syscallDispatcher(ulong ID, void* ret, void* params)
{
	//void* stackPtr;
	//asm {
	//	"movq %%rsp, %%rax" ::: "rax";
	//	"movq %%rax, %0" :: "o" stackPtr : "rax";
	//}//
	//kprintfln!("Syscall: ID = 0x{x}, ret = 0x{x}, params = 0x{x}")(ID, ret, params);
	mixin(MakeSyscallDispatchList!());
}


