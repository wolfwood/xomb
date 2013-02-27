module libos.libdeepmajik.umm;

import Syscall = user.syscall;

import user.environment;
import user.types;

class UserspaceMemoryManager{
	static:
	ubyte[] stacks;
	const uint pageSize = 4096;

	synchronized void initialize(){
		stacks = Syscall.create(findFreeSegment(false), AccessMode.User|AccessMode.Writable|AccessMode.AllocOnAccess);
	}

	synchronized ubyte* getPage(bool spacer = false){
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

	ubyte[] initHeap(){
		ulong i;
		ubyte[] foo = findFreeSegment(false, 512*oneGB);

		Syscall.create(foo, AccessMode.User|AccessMode.Writable|AccessMode.AllocOnAccess);

		return foo;
	}
}