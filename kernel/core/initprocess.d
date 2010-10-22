/* XOmB
 *
 * this code maps in the init process an the segemnts it expects
 * also jumps to userspace
 */

module kernel.core.initprocess;

// the basics
import kernel.core.error;
import kernel.core.kprintf;

// module definition
import kernel.system.info;

// gibs!
import architecture.vm;

// AccessMode, why is this here?
import user.environment;

struct InitProcess{
	static:
	ErrorVal install(){		
		// --- find module with init ---
		uint idx, j;

		char[] initname = "/binaries/init";

		for(idx = 0; idx < System.numModules; idx++) {
			kprintfln!("Checking {}")(System.moduleInfo[idx].name);
			//if(System.moduleInfo[idx].name == "/binaries/init"){
			if(System.moduleInfo[idx].name.length == initname.length){
				j = 0;
				while(j < System.moduleInfo[idx].name.length){
					if(initname[j] == System.moduleInfo[idx].name[j]){
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
			return ErrorVal.Fail;
		}

		// --- * turn module into gib ---
		ulong oneGB = 1024*1024*1024;

		// create gib at 1GB in kernel's page table or create new env
		// XXX: make only data & BSS writable?
		ubyte[] gibBytes =
			VirtualMemory.createSegment(cast(ubyte*)oneGB, oneGB,  AccessMode.Writable);
		//ubyte[] moduleBytes =
		//System.moduleInfo[idx].start[0..System.moduleInfo[idx].length];

		//XXX: are modules aligned? just map in pages?
		VirtualMemory.mapRegion(gibBytes.ptr, System.moduleInfo[idx].start, System.moduleInfo[idx].length);
		

		// gibify keyboard and console

		// * map in these gibs

		// map in other modules

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
}