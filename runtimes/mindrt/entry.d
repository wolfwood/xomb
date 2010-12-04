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
import libos.libdeepmajik.umm;

// Will be linked to the user's main function
int main(char[][]);

extern(C) ubyte _edata;
extern(C) ubyte _end;

ubyte* startBSS = &_edata;
ubyte* endBSS = &_end;

// Upcall Vector Table
void function()[2] UVT = [&start, &_enterThreadScheduler];
ubyte* UVTbase = cast(ubyte*)UVT.ptr;

ubyte[1024] tempStack;
ubyte* tempStackTop = &tempStack[tempStack.length - 8];


extern(C) void _start(int thing) {
	asm{
		naked;

		//stackless equivalent of "UVT[thing]();"
		movq RSI, UVTbase;
		sal RDI, 3;
		addq RSI, RDI;
		jmp [RSI];
	}
}

void start(){
	// Zero the BSS, equivalent to start2()

	asm {
		naked;

		// load the addresses of the beginning and end of the BSS
		mov RDX, startBSS;
		//mov RDX, [RDX];
		mov RCX, endBSS;
		//mov RCX, [RCX];

		// zero, one byte at a time
	loop:
		movb [RDX], 0;
		inc RDX;
		cmp RCX, RDX;
		jne loop;

		// now set the stack
		movq RSP, tempStackTop;
		
		call start3;
	}
}

void start2(){
	ubyte* startBSS = &_edata;
	ubyte* endBSS = &_end;

	for( ; startBSS != endBSS; startBSS++) {
		*startBSS = 0x00;
	}
	start3();
}

void start3(){
	//UsermodeMemoryManager.
	const static char[] name = "/binaries/app\0";
	const static char*[] args = [name.ptr, null];
	const static char** argv = args.ptr;
	ulong argvul = cast(ulong)argv;
	// __ENV ?

	init();

	XombThread* mainThread = threadCreate(&main);

	mainThread.schedule();

	asm{
		mov RDI, 1;
		mov RSI, argvul;
	}

	_enterThreadScheduler();
}
