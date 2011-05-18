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
import kernel.dev.keyboard;

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
				
		// XXX: create null gib without alloc on access

		// --- * turn module into segment ---
		if(createSegmentForModule(initname, 1) is null){
			return ErrorVal.Fail;
		}

		if(!testForMagicNumber()){
			kprintfln!("Bad magic cookie from Init. Blech -- XOmB only work for 0xdeadbeefcafe cookies")();
			return ErrorVal.Fail; 
		}

		MessageInAbottle* bottle = MessageInAbottle.getMyBottle();

		// XXX: replace fixed values with findFreeGib()
		bottle.stdout = (cast(ubyte*)findFreeSegment!(false))[0..oneGB];
		bottle.stdin = (cast(ubyte*)findFreeSegment!(false))[0..oneGB];

		// * map in video and keyboard segments
		VirtualMemory.mapSegment(null, Console.virtualAddress(), bottle.stdout.ptr, AccessMode.Writable);
		bottle.stdoutIsTTY = true;

		VirtualMemory.mapSegment(null, Keyboard.address, bottle.stdin.ptr, AccessMode.Writable);
		bottle.stdinIsTTY = true;

		bottle.setArgv("init and args");

    // this page table becomes init's page table.  Init is its own [grand]mother.
    root.getOrCreateTable(255).entries[0].pml = root.entries[511].pml;

		return ErrorVal.Success; 
	}


	void enter(){
		// use CPUid as vector index and sysret to 1 GB

		// jump using sysret to 1GB for stackless entry
		ulong mySS = ((8UL << 3) | 3);
		ulong myRSP = 0;
		ulong myFLAGS = ((1UL << 9) | (3UL << 12));
		ulong myCS = ((9UL << 3) | 3);
		ulong entry = oneGB + ulong.sizeof*2;

		asm{
			movq R11, mySS;
			pushq R11;
			
			movq R11, myRSP;
			pushq R11;

			movq R11, myFLAGS;
			pushq R11;

			movq R11, myCS;
			pushq R11;

			movq R11, entry;
			pushq R11;

			movq RDI, 1;

			iretq;
		}
	}

	void enterFromBSP(){
		// jump using sysret to 1GB for stackless entry
		ulong mySS = ((8UL << 3) | 3);
		ulong myRSP = 0;
		ulong myFLAGS = ((1UL << 9) | (3UL << 12));
		ulong myCS = ((9UL << 3) | 3);
		ulong entry = oneGB + ulong.sizeof*2;

		asm{
			movq R11, mySS;
			pushq R11;
			
			movq R11, myRSP;
			pushq R11;

			movq R11, myFLAGS;
			pushq R11;

			movq R11, myCS;
			pushq R11;

			movq R11, entry;
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
	bool testForMagicNumber(ulong pass = oneGB){
		ulong* addy = cast(ulong*)pass;

		if(addy[1] == 0xdeadbeefcafeUL){
			return true;
		}
		return false;
	}

	ubyte[] createSegmentForModule(char[] name, int segidx = -1){
		int idx = findIndexForModuleName(name);

		// is it more annoying to assume a path and name for init or assume that its the first module?
		// grub2 doesn't give us the name anymore, so we are assuming its the first module
		if(idx == -1){
			idx = 0;
		}

		if(idx == -1){
			kprintfln!("Init NOT found")();
			return null;
		}

		if(segidx == -1){
			// XXX: find a free gib
			kprintfln!("dunno where to stick init")();
			return null;
		}

		//kprintfln!("Init found at module index {} with start {} and length{}")(idx, System.moduleInfo[idx].start, System.moduleInfo[idx].length);

		ubyte[] segmentBytes =
			VirtualMemory.createSegment(cast(ubyte*)(segidx*oneGB), oneGB, AccessMode.Writable);

		VirtualMemory.mapRegion(segmentBytes.ptr, System.moduleInfo[idx].start, System.moduleInfo[idx].length);
		
		// set module length in first ulong of segment
		*cast(ulong*)segmentBytes.ptr = System.moduleInfo[idx].length;

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