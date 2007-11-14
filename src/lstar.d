import vga;

/**
Very basic system call handler. Simply prints out a message to the screen
informing the user a system call has been thrown.
*/
void syscallHandler() {
	kprintfln("A system call has been thrown.");
} // set syscallHandler

/**
This function declares a handler for system calls. It accepts a pointer to a function (h).
h will be called to fully handle the system call, depending on the register values for the system call.
	Params:
		h = A function that will be tied to the system call to handle it.
*/
void set_handler(void function() h) {
	ulong addy = cast(ulong) h;
	uint hi = addy >> 32;
	uint lo = addy;
	uint code = 0xC0000082;

	kprintfln("Setting the Handler.");

	/// Set data in the lstar registers properly that the handler will be there when
	/// the kernel requires it.
	asm {
		"mov %0, %%edx\n\t"
		"mov %1, %%eax\n\t"
		"mov %2, %%ecx\n\t"
		"wrmsr"
		: /* no output */
		: "r" hi, "r" lo, "r" code
		: "edx", "eax", "ecx";
	}
}

