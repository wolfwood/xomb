import vga;

/**
This function declares a handler for system calls. It accepts a pointer to a function (h).
h will be called to fully handle the system call, depending on the register values for the system call.

Params:
	h = A function that will be tied to the system call to handle it.
*/
void setHandler(void* h)
{
	/* We commented this out because it is causing infinite 
		page faults. */
		
	ulong addy = cast(ulong) h;
	uint hi = addy >> 32;
	uint lo = addy & 0xFFFFFFFF;
	const ulong msr = 0xc0000082;

	kprintfln("Setting the Handler.");

	/// Set data in the lstar registers properly that the handler will be there when
	/// the kernel requires it.
	asm
	{
		"movl %0, %%edx\n"
		"movl %1, %%eax\n"
		"movq %2, %%rcx\n" :: "r" hi, "r" lo, "i" msr : "edx", "eax", "rcx";
		"wrmsr";
		
	}
	
	// now set STAR
        const ulong STAR = 0x003b_0010_0000_0000;
	const uint STARHI = STAR >> 32;
	const uint STARLO = STAR & 0xFFFFFFFF;
	
	asm
	{
		// Set the STAR register.
		"movl $0xC0000081, %%ecx\n"
		"movl %0, %%edx\n"
		"movl %1, %%eax" :: "i"STARHI, "i"STARLO : "ecx", "edx", "eax";
		//"movl $0xC0000081, %%ecx" ::: "ecx";
		//"movl %0, %%edx" :: "i" STARHI : "edx";
		//"movl %0, %%eax" :: "i" STARLO : "eax";
		"wrmsr";
	}
	
	// now set SF_MASK
	
	asm
	{
		// Set the SF_MASK register.  Top should be 0, bottom is our mask,
		// but we're not masking anything (yet).
		"xorl %%eax, %%eax" ::: "eax";
		"xorl %%edx, %%edx" ::: "edx";
		"movl $0xC0000084, %%ecx" ::: "ecx";
		"wrmsr";
	}
}

void sysCallHandler()
{
	// we should get arguments and retain %rcx
	asm
	{
		naked;
		// etc: "popq %rdi";

		// push program counter to stack
		"pushq %%rcx";
	}

	kprintfln("In sysCall Handler");

	asm
	{
		naked;		
		"popq %%rcx";
		"sysretq";
	}
}