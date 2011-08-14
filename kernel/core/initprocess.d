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

// enterUserspace()
import architecture.cpu;

// bottle
import user.ipc;


struct InitProcess{
	static:

	// rather than creating a new AddressSpace, since the kernel is mapped in to all,
	// we instead map init into the lower half of the current AddressSpace
	ErrorVal install(){
		uint idx, j;

		char[] initname = "init";

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

		// * map in video and keyboard segments
		bottle.stdout = findFreeSegment(false, Console.segment.length);
		VirtualMemory.mapSegment(null, Console.segment, bottle.stdout.ptr, AccessMode.Writable|AccessMode.User);
		bottle.stdoutIsTTY = true;

		bottle.stdin = findFreeSegment(false, Keyboard.segment.length);
		VirtualMemory.mapSegment(null, Keyboard.segment, bottle.stdin.ptr, AccessMode.Writable|AccessMode.User);
		bottle.stdinIsTTY = true;

		bottle.setArgv("init and args");

    // this page table becomes init's page table.  Init is its own [grand]mother.
    root.getOrCreateTable(255).entries[0].pml = root.entries[510].pml;
		root.getTable(255).entries[0].setMode(AccessMode.RootPageTable);

		return ErrorVal.Success;
	}

	void enterFromBSP(){
		// init shouldn't care where its entered from
		PhysicalAddress physAddr;

		// jump using sysret to 1GB for stackless entry
		Cpu.enterUserspace(0, physAddr);
	}

	void enterFromAP(){
		// wait for acknowledgement?
		for(;;){}


		PhysicalAddress physAddr;

		Cpu.enterUserspace(1, physAddr);
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

		ubyte[] segmentBytes = (cast(ubyte*)(segidx*oneGB))[0..oneGB];

		VirtualMemory.createSegment(segmentBytes, AccessMode.User|AccessMode.Writable|AccessMode.AllocOnAccess|AccessMode.Executable);

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