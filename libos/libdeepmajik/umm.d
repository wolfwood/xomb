module libos.libdeepmajik.umm;

import Syscall = user.syscall;

import user.environment;
import user.types;


class UserspaceMemoryManager{
	static:

	const ulong stackSize = twoMB;

	synchronized void initialize(){

	}

	synchronized ubyte* getPage(bool spacer = false){
		ubyte[] stacks = Syscall.create(findFreeSegment(false, UserspaceMemoryManager.stackSize), AccessMode.User|AccessMode.Writable|AccessMode.AllocOnAccess);

		if(stacks.length < UserspaceMemoryManager.stackSize){return null;}

		Syscall.create(stacks[0..fourKB], AccessMode.Read);

		return &stacks[$];
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