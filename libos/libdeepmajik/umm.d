module libos.libdeepmajik.umm;

import Syscall = user.syscall;

import user.types;

class UserspaceMemoryManager{
	static:
	ubyte[] stacks;
	ubyte* stackGib = cast(ubyte*)(254UL << ((9*3) + 12));
	const uint pageSize = 4096;

	synchronized void initialize(){
		stacks = Syscall.create(stackGib, 1024*1024*1024, AccessMode.User|AccessMode.Writable|AccessMode.AllocOnAccess);
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
			= Syscall.create(cast(ubyte*)(20*oneGB), 1024*1024*1024, AccessMode.User|AccessMode.Writable|AccessMode.AllocOnAccess);

		for(i = 1; i < 4; i++){
			Syscall.create(cast(ubyte*)((20+1)*oneGB), 1024*1024*1024, AccessMode.User|AccessMode.Writable|AccessMode.AllocOnAccess);
		}

		foo = foo.ptr[0..(i*oneGB)];

		return foo;
	}
}