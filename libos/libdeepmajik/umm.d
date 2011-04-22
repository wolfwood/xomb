module libos.libdeepmajik.umm;

import user.syscall;

// AccessMode
import user.environment;

class UserspaceMemoryManager{
	static:
	ubyte[] stacks;
	ubyte* stackGib = cast(ubyte*)(254UL << ((9*3) + 12));
	const uint pageSize = 4096;

	synchronized void init(){
		stacks = create(stackGib, 1024*1024*1024, AccessMode.Writable);
	}

	synchronized ubyte* getPage(bool spacer = false){
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

	synchronized void freePage(ubyte* page){
		// XXX: Actually Free Page
		return;
	}

	// XXX: heap is limited to 4 GB
	ubyte[] initHeap(){
		ulong i;
		ubyte[] foo 
			= create(cast(ubyte*)(20*oneGB), 1024*1024*1024, AccessMode.Writable);

		for(i = 1; i < 4; i++){
			create(cast(ubyte*)((20+1)*oneGB), 1024*1024*1024, AccessMode.Writable);
		}

		foo = foo.ptr[0..(i*oneGB)];

		return foo;
	}
}