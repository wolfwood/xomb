/*
 * entry.d
 *
 * The entry point to an app.
 *
 * License: Public Domain
 *
 */

import libos.libdeepmajik.threadscheduler;
import libos.libdeepmajik.umm;

import user.ipc;

import libos.console;
import libos.keyboard;


/*
 * --- Upcall Vector Table ---
 * all control transfers jump to _start (in entry.S).  it redirects control, based on RAX
 *
 * 0 - Initial Entry (from parent, should only happen once)
 * 1 - CPU Allocation/Donation (give cpu to thread scheduler)
 * 2 - Child Exit (should trigger cleanup, along with the next one)
 * 3 - Child Error (from kernel, rather than yield)
 * ? - Inter Process Communication
*/
void function()[4] UVT = [&start,
													&XombThread._enterThreadScheduler,
													&XombThread._enterThreadScheduler,
													&XombThread._enterThreadScheduler];

// used by asm function _start to route upcalls
extern(C) ubyte* UVTbase = cast(ubyte*)UVT.ptr;
extern(C) ulong UVTlimit = UVT.length;


/*
 * --- Initial Entry Chain ---
 * split into 3 functions:
 *
 * start  - stackless, zeros bss
 * start2 - static stack, libos initialization and thread creation
 * start3 - thread stack, runtime specific initialization, calls main()
 */


// Declarations used to find and zero BSS
extern(C) ubyte _bss;
extern(C) ubyte _end;
ubyte* startBSS = &_bss;
ubyte* endBSS = &_end;

// temporary stack
ubyte[4096*4] tempStack;
ubyte* tempStackTop = &tempStack[tempStack.length - 8];


// provided by runtime, calls main
extern(C) void start3(char[][]);

// zeros BSS and gives us a temporary (statically allocated) stack
void start(){
	asm {
		naked;

		// zero rbp
		xor RBP, RBP;

		// load the addresses of the beginning and end of the BSS
		mov RDX, startBSS;
		//mov RDX, [RDX];
		mov RCX, endBSS;
		//mov RCX, [RCX];

		// if bss is zero size, skip
		cmp RCX, RDX;
		je setupstack;

		// zero, one byte at a time
	loop:
		movb [RDX], 0;
		inc RDX;
		cmp RCX, RDX;
		jne loop;

	setupstack:
		// now set the stack
		movq RSP, tempStackTop;

		call start2;
	}

	// >>> Never reached <<<
}

// initializes console and keyboard, umm and threading, chain loads a thread
void start2(){
	char[][] argv = MessageInAbottle.getMyBottle().argv;

	ulong argvlen = cast(ulong)argv.length;
	ulong argvptr = cast(ulong)argv.ptr;
	// __ENV ?

	MessageInAbottle* bottle = MessageInAbottle.getMyBottle();

	if(bottle.stdoutIsTTY){
		Console.initialize(bottle.stdout.ptr);
	}

	if(bottle.stdinIsTTY){
		Keyboard.initialize(cast(ushort*)bottle.stdin.ptr);
	}

	UserspaceMemoryManager.initialize();
	XombThread.initialize();

	XombThread* mainThread = XombThread.threadCreate(&start3, argvlen, argvptr);

	mainThread.schedule();

	XombThread._enterThreadScheduler();

	// >>> Never reached <<<
}