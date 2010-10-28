module libos.libdeepmajik.umm;

import user.syscall;

// AccessMode
import user.environment;

//struct UserspaceMemoryManager{
	ubyte[] stacks;
	ubyte* stackGib = cast(ubyte*)(254UL << ((9*3) + 12));
	const uint pageSize = 4096;

	void init(){
		stacks = create(stackGib, 1024*1024*1024, AccessMode.Writable);
	}

	ubyte* getPage(bool spacer = false){
		//pageStack -= 4096;
	
		//ubyte* temp = pageStack;

		//allocPage(cast(ubyte*)pageStack);
	
		//if(spacer){pageStack -= 4096;}

		//return temp;

		if(stacks.length < pageSize){return null;}

		ubyte[] stack = stacks[(length - pageSize).. length];

		stacks = stacks[0..(length -pageSize)];

		if(spacer){stacks = stacks[0..(length -pageSize)];}

		return stack.ptr;
	}

	void freePage(ubyte* page){
		// XXX: Actually Free Page
		return;
	}
//}