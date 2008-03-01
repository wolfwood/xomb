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

	kprintfln("Setting the Handler.");

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
	// we should get arguments and retain %rcx
// 	asm
// 	{
// 		naked;
// 		
// 		"mov 0xfffffffffffffff8(%%rbp), %%rdi";// :: "r" ID;      //rdi
// 		"mov 0xfffffffffffffff0(%%rbp), %%rsi";// :: "r" ret;     //rsi
// 		"mov 0xffffffffffffffe8(%%rbp), %%rdx";// :: "r" params;  //rdx
// 
// 		// push program counter to stack
// 		"pushq %%rcx";
// 	}

	ulong ID;
	void* ret;
	void* params;

	asm
	{
		"mov %%rdi, %0" :: "o" ID;      //rdi
		"mov %%rsi, %0" :: "o" ret;     //rsi
		"mov %%rdx, %0" :: "o" params;  //rdx
	}

	auto addargs = cast(AddArgs*)params;

	kprintfln("Syscall: ID = 0x%x, ret = 0x%x, params = 0x%x", ID, ret, params);
	kprintfln("Add args: a=%d, b=%d", addargs.a, addargs.b);

	asm
	{
		naked;		
		"popq %%rcx";
		"sysretq";
	}
}
