/*
 * entry.d
 *
 * The entry point to an app.
 *
 */

import user.syscall;

import libos.libdeepmajik.threadscheduler;

// Will be linked to the user's main function
int main(char[][]);

//extern(C) ubyte _bss;
//extern(C) ubyte _ebss;
extern(C) ubyte _edata;
extern(C) ubyte _end;

extern(C) void _start() {
	// Zero the bss 

	asm {
		pushq 0;
	}

	ubyte* startBSS = &_edata;
	ubyte* endBSS = &_end;

	//dispUlong(cast(ulong)startBSS);
	//dispUlong(cast(ulong)endBSS);

	for( ; startBSS != endBSS; startBSS++) {
		*startBSS = 0x00;
	}


	XombThread* mainThread = threadCreate(&main);

	mainThread.schedule();

	_enterThreadScheduler();
}
