import vga;

import syscalluser;

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

void sysCallHandler()
{
	asm
	{
		naked;
		// push program counter to stack
		"pushq %%rcx";
		"pushq %%r11";
		"callq sysCallDispatcher";
		"popq %%r11";
		"popq %%rcx";
		"sysretq";
	}
}

extern(C) void sysCallDispatcher(ulong ID, void* ret, void* params)
{
	auto addargs = cast(AddArgs*)params;

	kprintfln!("Add args!")();
	kprintfln!("Add args: a = {}, b = {}")(addargs.a, addargs.b);
	kprintfln!("Syscall: ID = 0x{x}, ret = 0x{x}, params = 0x{x} (args = 0x{x})")(ID, ret, params, addargs);
	kprintfln!("Add args: a = {}, b = {}")(addargs.a, addargs.b);
}