/*
 * entry.d
 *
 * The entry point to an app.
 *
 */

// Will be linked to the user's main function
int main(char[][]);

extern ubyte _bss;
extern ubyte _ebss;

extern(C) void _start() {
	// Zero the bss 

	ubyte* startBSS = &_bss;
	ubyte* endBSS = &_ebss;

	for( ; startBSS != endBSS; startBSS++) {
		*startBSS = 0x00;
	}

	main(null);

	// exit();
}
