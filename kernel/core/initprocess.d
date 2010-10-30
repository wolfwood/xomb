/* XOmB
 *
 * this code maps in the init process an the segemnts it expects
 * also jumps to userspace
 */

module kernel.core.initprocess;

// the basics
import kernel.core.error;
import kernel.core.kprintf;

// console gib
import kernel.dev.console;

// module definition
import kernel.system.info;

// gibs!
import architecture.vm;

// AccessMode, why is this here?
import user.environment;

struct InitProcess{
	static:

	// rather than creating a new AddressSpace, since the kernel is mapped in to all, 
	// we instead map init into the lower half of the current AddressSpace
	ErrorVal install(){
		uint idx, j;

		char[] initname = "/binaries/init";
		char[] helloname = "/banaries/hello";
		
		// XXX: create null gib without alloc on access

		// --- * turn module into segment ---
		// XXX: make only data & BSS writable?
		if(createSegmentForModule(initname, 1) is null){
			return ErrorVal.Fail;
		}

		// * map in video and keyboard segments
		VirtualMemory.mapSegment(null, Console.virtualAddress(), cast(ubyte*)(2*oneGB), AccessMode.Writable);

		// map in other modules
		createSegmentForModule(helloname, 3);

		return ErrorVal.Success; 
	}


	void enter(){
		// use CPUid as vector index and sysret to 1 GB

		for(;;){}
	}

	void enterFromBSP(){
		// jump using sysret to 1GB for stackless entry
		ulong mySS = ((8UL << 3) | 3);
		ulong myRSP = 0;
		ulong myFLAGS = ((1UL << 9) | (3UL << 12));
		ulong myCS = ((9UL << 3) | 3);
		ulong oneGB = 1024*1024*1024;

		//for(;;){}
		asm{
			movq R11, mySS;
			pushq R11;
			
			movq R11, myRSP;
			pushq R11;

			movq R11, myFLAGS;
			pushq R11;

			movq R11, myCS;
			pushq R11;

			movq R11, oneGB;
			pushq R11;

			movq RDI, 0;

			iretq;
		}
	}

	void enterFromAP(){
		// wait for acknoledgement?

		// jump using sysret to 1GB for stackless entry

		for(;;){}
	}

private:
	const ulong oneGB = 1024*1024*1024;

	ubyte[] createSegmentForModule(char[] name, int segidx = -1){
		int idx = findIndexForModuleName(name);

		if(idx == -1){
			return null;
		}

		if(segidx == -1){
			// XXX: find a free gib
			return null;
		}

		ubyte[] segmentBytes =
			VirtualMemory.createSegment(cast(ubyte*)(segidx*oneGB), oneGB, AccessMode.Writable);

		VirtualMemory.mapRegion(segmentBytes.ptr, System.moduleInfo[idx].start, System.moduleInfo[idx].length);

		return segmentBytes;
	}

	int findIndexForModuleName(char[] name){
		int idx, j;
		for(idx = 0; idx < System.numModules; idx++) {

			if(System.moduleInfo[idx].name.length == name.length){
				j = 0;
				while(j < System.moduleInfo[idx].name.length){
					if(name[j] == System.moduleInfo[idx].name[j]){
						j++;
					}else{
						break;
					}
				}

				if(j ==  System.moduleInfo[idx].name.length){
					break;
				}
			}
		}

		if(idx >= System.numModules){
			// no match for initname was found
			return -1;
		}

		return idx;
	}
}