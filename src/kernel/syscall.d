module kernel.syscall;



import kernel.vga;

import user.syscall;
import core.util;

/**
This function declares a handler for system calls. It accepts a pointer to a function (h).
h will be called to fully handle the system call, depending on the register values for the system call.

Params:
	h = A function that will be tied to the system call to handle it.
*/
void setHandler(void* h)
{
	const ulong STAR_MSR = 0xc000_0081;
	const ulong LSTAR_MSR = 0xc000_0082;
	const ulong SFMASK_MSR = 0xc000_0084;

	const ulong STAR = 0x003b_0010_0000_0000;
	const uint STARHI = STAR >> 32;
	const uint STARLO = STAR & 0xFFFF_FFFF;

	ulong addy = cast(ulong)h;
	uint hi = addy >> 32;
	uint lo = addy & 0xFFFFFFFF;

	kprintfln!("Setting the Handler.")();

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

// alright, so %rdi, %rsi, %rdx are the registers loaded by NativeSyscall()
//

void syscallHandler()
{
	asm
	{
		naked;
		// make sure to preserve the return address and flags
		//"pushq %%rbp";
		//"movq %%rbp, %%rsp";
		"pushq %%rcx";
		"pushq %%r11";
		"callq syscallDispatcher";
		"popq %%r11";
		"popq %%rcx";
		//"popq %%rbp";
		"sysretq";
	}
}

template MakeSyscallDispatchCase(uint idx)
{
	static if(!is(SyscallRetTypes[idx] == void))
		const char[] MakeSyscallDispatchCase =
`case ` ~ idx.stringof ~ `:
	return syscall` ~ Capitalize!(SyscallName!(idx)) ~ `(*(cast(` ~ SyscallRetTypes[idx].stringof ~
	`*)ret), cast(` ~ ArgsStruct!(idx) ~ `*)params);`;
	else
		const char[] MakeSyscallDispatchCase =
`case ` ~ idx.stringof ~ `:
	return syscall` ~ Capitalize!(SyscallName!(idx)) ~ `(cast(` ~ ArgsStruct!(idx) ~ `*)params);`;
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
	//kprintfln!("Syscall: ID = 0x{x}, ret = 0x{x}, params = 0x{x}")(ID, ret, params);
	mixin(MakeSyscallDispatchList!());
}

// Syscall Implementations

// add two numbers, a and b, and return the result
// ulong add(long a, long b)
SyscallError syscallAdd(out long ret, AddArgs* params)
{
	ret = params.a + params.b;
	return SyscallError.OK;
}

// void* allocPage(ulong num)
SyscallError syscallAllocPage(out void* ret, AllocPageArgs* params)
{
	kprintfln!("WARNING: allocPage() not yet implemented")();
	ret = null;
	return SyscallError.Failcopter;
}

// void exit(ulong retval)
SyscallError syscallExit(ExitArgs* params)
{
	kprintfln!("WARNING: exit() not yet implemented")();
	return SyscallError.Failcopter;
}
