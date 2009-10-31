/*
 * entry.d
 *
 * The entry point to an app.
 *
 */

import user.syscall;

// Will be linked to the user's main function
int main(char[][]);

extern(C) ubyte _bss;
extern(C) ubyte _ebss;

extern(C) void _start() {
	// Zero the bss 

	asm {
		pushq 0;
	}

	ubyte* startBSS = &_bss;
	ubyte* endBSS = &_ebss;

	for( ; startBSS != endBSS; startBSS++) {
		*startBSS = 0x00;
	}

	main(null);

	exit(0);
}
