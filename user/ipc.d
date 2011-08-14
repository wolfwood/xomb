module user.ipc;

import user.environment;

import Syscall = user.syscall;

// place to store values that must be communicated to the child process from the parent
struct MessageInAbottle {
	ubyte[] stdin;
	ubyte[] stdout;
	bool stdinIsTTY, stdoutIsTTY;
	char[][] argv;

	int exitCode;

	// assumes alloc on write beyond end of exe
	void setArgv(char[][] parentArgv, ubyte[] to = (cast(ubyte*)oneGB)[0..oneGB]){
		// assumes allocation on write region exists immediately following bottle

		// allocate argv's array reference array first, since we know how long it is
		argv = (cast(char[]*)this + MessageInAbottle.sizeof)[0..parentArgv.length];

		// this will be a sliding window for the strngs themselves, allocated after the argv array reference array
		char[] storage = (cast(char*)argv[length..length].ptr)[0..0];

		foreach(i, str; parentArgv){
			storage = storage[length..length].ptr[0..(str.length+1)]; // allocate an extra space for null terminator

			storage[0..(str.length)] = str[];

			storage[(str.length)] = '\0';  // stick on null terminator

			argv[i] = storage[0..(str.length)];
		}

		// adjust pointers
		adjustArgvPointers(to);
	}

	void setArgv(char[] parentArgv,  ubyte[] to = (cast(ubyte*)oneGB)[0..oneGB]){

		// allocate strings first, since we know how long they are
		char[] storage = (cast(char*)this + MessageInAbottle.sizeof)[0..(parentArgv.length +1)];

		storage[0..($-1)] = parentArgv[];

		// determine length of array reference array
		int substrings = 1;

		foreach(ch; storage){
			if(ch == ' '){
				substrings++;
			}
		}

		storage[($-1)] = '\0';

		// allocate array reference array
		argv = (cast(char[]*)storage[length..length].ptr)[0..substrings];

		char* arg = storage.ptr;
		int len, i;

		foreach(ref ch; storage){
			if(ch == ' '){
				ch = '\0';
				argv[i] = arg[0..len];
				len++;
				len++;
				arg = arg[len..len].ptr;
				len = 0;
				i++;
			}else{
				len++;
			}
		}//end foreach

		// final sub array isn't (hopefully) followed by a space, so it
		// will bot get assigned in loop, and we must do it here instead

		argv[i] = (arg)[0..len];

		adjustArgvPointers(to);
	}

private:
	void adjustArgvPointers(ubyte[] to){
		// exploits fact that all argv pointers are intra-segment, so it
		// is enought to mod (mask) by the segment size and then add the
		// new segment base address

		foreach(ref str; argv){
			str = (cast(char*)(to.ptr + (cast(ulong)str.ptr & (to.length -1) )))[0..str.length];
		}

		argv = (cast(char[]*)(to.ptr + (cast(ulong)argv.ptr & (to.length -1) )))[0..argv.length];
	}

	public static:
	MessageInAbottle* getBottleForSegment(ubyte* seg){
		return cast(MessageInAbottle*)(seg + (oneGB - 4096));
	}

	MessageInAbottle* getMyBottle(){
		return getBottleForSegment(cast(ubyte*) oneGB);
	}
}


template populateChild(T){
	void populateChild(T argv, AddressSpace child, ubyte[] f, ubyte[] stdin = null, ubyte[] stdout = null){
		// XXX: restrict T to char[] and char[][]

		// map executable to default (kernel hardcoded) location in the child address space
		ubyte* dest = cast(ubyte*)oneGB;

		assert(child !is null && f !is null && dest !is null, "NULLS!!!!!\n");

		version(KERNEL){
			// kernel only executes init once, so its OK not to copy
		}else{
			ubyte[] g = findFreeSegment(false);

			Syscall.create(g, AccessMode.Writable|AccessMode.User|AccessMode.Executable|AccessMode.AllocOnAccess);

			// XXX: instead of copying the whole thing we should only be duping the r/w data section
			uint len = *(cast(ulong*)f.ptr) + ulong.sizeof;
			g[0..len] = f.ptr[0..len];

			f = g[0..f.length];
		}

		Syscall.map(child, f, dest, AccessMode.Writable|AccessMode.User|AccessMode.Executable|AccessMode.AllocOnAccess);

		// bottle to bottle transfer of stdin/out isthe default case
		MessageInAbottle* bottle = MessageInAbottle.getMyBottle();
		MessageInAbottle* childBottle = MessageInAbottle.getBottleForSegment(f.ptr);


		childBottle.stdoutIsTTY = false;
		childBottle.stdinIsTTY = false;

		childBottle.setArgv(argv);

		AccessMode stdoutMode = AccessMode.Writable|AccessMode.User;

		// if no stdin/out is specified, us the same buffer as parent
		if(stdout is null){
			stdout = bottle.stdout;
			childBottle.stdoutIsTTY = bottle.stdoutIsTTY;
		}

		if(!childBottle.stdoutIsTTY){
			stdoutMode |= AccessMode.AllocOnAccess;
		}

		if(stdin is null){
			stdin = bottle.stdin;
			childBottle.stdinIsTTY = bottle.stdinIsTTY;
		}

		// XXX: use findFreeSemgent to pick gib locations in child
		childBottle.stdout = (cast(ubyte*)(2*oneGB))[0..stdout.length];
		childBottle.stdin = (cast(ubyte*)(3*oneGB))[0..stdin.length];

		// map stdin/out into child process
		Syscall.map(child, stdout, childBottle.stdout.ptr, stdoutMode);
		Syscall.map(child, stdin, childBottle.stdin.ptr, AccessMode.Writable|AccessMode.User);
	}
}
