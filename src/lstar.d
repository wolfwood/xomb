import vga;

/**
This function declares a handler for system calls. It accepts a pointer to a function (h).
h will be called to fully handle the system call, depending on the register values for the system call.

Params:
	h = A function that will be tied to the system call to handle it.
*/
void setHandler(void* h)
{
	ulong addy = cast(ulong) h;
	uint hi = addy >> 32;
	uint lo = addy & 0xFFFFFFFF;
	const ulong msr = 0xc0000082;

	kprintfln("Setting the Handler.");

	/// Set data in the lstar registers properly that the handler will be there when
	/// the kernel requires it.
	asm
	{
		"movl %0, %%edx" :: "r" hi : "edx";
		"movl %0, %%eax" :: "r" lo : "eax";
		"movq %0, %%rcx" :: "i" msr : "rcx";
		"wrmsr";
	}
}

