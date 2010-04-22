/*
 * entry.d
 *
 * The entry point to an app.
 *
 * License: Public Domain
 *
 */

import user.syscall;

import libos.libdeepmajik.threadscheduler;

// Will be linked to the user's main function
int main(); //char[][]);

//extern(C) ubyte _bss;
//extern(C) ubyte _ebss;

extern(C) ubyte _edata;
extern(C) ubyte _end;

extern(C) void _start() {
	 asm{
		 naked;
		 popq RDI;
		 popq RSI;

		 call start;
	}
}
extern(C) void start(char[] argv) {
	// Zero the bss 


	log("hi");
	log(argv);

	/*asm {
		pushq 0;
		}*/

	ubyte* startBSS = &_edata;
	ubyte* endBSS = &_end;

	for( ; startBSS != endBSS; startBSS++) {
		*startBSS = 0x00;
	}


	//main();

	XombThread* mainThread = threadCreate(&main);

	mainThread.schedule();

	_enterThreadScheduler();
}
