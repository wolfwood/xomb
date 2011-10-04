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

// Will be linked to the user's main function
int main(char[][]);

extern(C) ubyte _edata;
extern(C) ubyte _bss;
extern(C) ubyte _end;

ubyte* startBSS = &_bss;
ubyte* endBSS = &_end;

// Upcall Vector Table -- first entry, cpu allocation, child exit, child error (from kernel)
void function()[4] UVT = [&start, &XombThread._enterThreadScheduler, &XombThread._enterThreadScheduler, &XombThread._enterThreadScheduler];
extern(C) ubyte* UVTbase = cast(ubyte*)UVT.ptr;

ubyte[1024] tempStack;
ubyte* tempStackTop = &tempStack[tempStack.length - 8];


void start(){
	// Zero the BSS, equivalent to start2()

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

		call start3;
	}
}

void start3(){
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

	XombThread* mainThread = XombThread.threadCreate(&main, argvlen, argvptr);

	mainThread.schedule();

	XombThread._enterThreadScheduler();
}
