import vga;

import syscalluser;
import util;

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
		"pushq %%rbp";
		"movq %%rbp, %%rsp";
		"pushq %%rcx";
		"pushq %%r11";
		"callq syscallDispatcher";
		"popq %%r11";
		"popq %%rcx";
		"popq %%rbp";
		"sysretq";
	}
}

template MakeSyscallDispatchListCase(SyscallID idx, char[] name)
{
	const char[] MakeSyscallDispatchListCase =
	`case ` ~ Itoa!(idx) ~ `:

		kprintfln!("Syscall Identified: ` ~ name ~ `")();
		syscall_` ~ name ~ `(ret, cast(` ~ name ~ `Args*)params);
		break;`;
}

template MakeSyscallDispatchList()
{
	const char[] MakeSyscallDispatchList =
	`switch(ID)
	{`
		~ MakeSyscallDispatchListCase!(SyscallID.Add, "add")
		~ MakeSyscallDispatchListCase!(SyscallID.AllocPage, "allocPage")
		~ MakeSyscallDispatchListCase!(SyscallID.Exit, "exit")
		~
	`default:
		kprintfln!("Syscall not supported!")();
	}`;
}

extern(C) void syscallDispatcher(ulong ID, void* ret, void* params)
{
	kprintfln!("Syscall: ID = 0x{x}, ret = 0x{x}, params = 0x{x}")(ID, ret, params);
	mixin(MakeSyscallDispatchList!());
}

// Syscall Implementations

// ulong add(long a, long b)
void syscall_add(void* ret, addArgs* params)
{
	// add two numbers, a and b, and return the result
	*(cast(long*)ret) = params.a + params.b;
}

// allocPage
void syscall_allocPage(void* ret, allocPageArgs* params)
{
	kprintfln!("WARNING: allocPage() not yet implemented")();
	*(cast(void**)ret) = null;
}

// void exit(ulong retval)
void syscall_exit(void* ret, exitArgs* params)
{
	kprintfln!("WARNING: exit() not yet implemented")();
}