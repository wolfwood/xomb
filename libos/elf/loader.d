/*
 * loader.d
 *
 * This module can load an executable.
 *
 */

module libos.elf.loader;

import mindrt.util;

import libos.elf.elf;
import libos.elf.segment;

//import libos.console;

import user.environment;
import user.syscall;

struct Loader {
	static:
	
	bool flatLoad(ubyte[] binary, AddressSpace child) {
		// XXX: use findFreeSegment()
		ubyte[] here = create(cast(ubyte*)(10*oneGB), oneGB, AccessMode.Writable|AccessMode.AllocOnAccess);  


		memcpy(cast(void*)here.ptr, cast(void*)binary.ptr, binary.length);
		
		//XXX: close(here.ptr)
		map(child, here.ptr, cast(ubyte*)oneGB, AccessMode.Writable|AccessMode.AllocOnAccess); 
		
		return true;
	}


	// This function will load an executable from a module, if it can.
	bool load(ubyte[] binary, AddressSpace child) {
		ubyte* binaryAddr = binary.ptr;

		void* entryAddress = Elf.getentry(binaryAddr);
		void* physAddress = Elf.getphysaddr(binaryAddr);
		void* virtAddress = Elf.getvirtaddr(binaryAddr);
		//kprintfln!("ELF Module : {}\n  Entry: {x} p: {x} v: {x}")(index, entryAddress, physAddress, virtAddress);


		assert(virtAddress == cast(void*)oneGB);

		// XXX: use findFreeSegment()
		ubyte[] here = create(cast(ubyte*)(10*oneGB), oneGB, AccessMode.Writable|AccessMode.AllocOnAccess);  

		Segment curSegment;

		uint numSegments = Elf.segmentCount(binaryAddr);

		if (here is null) {
			return false;
		}
		else {
		
			for(uint i; i < numSegments; i++) {
				curSegment = Elf.segment(binaryAddr, i);

				//XXX: make respect s.writable, later
				//environ.allocSegment(curSegment);

				// Copy segment
				memcpy(here.ptr + (curSegment.virtAddress - virtAddress), binaryAddr + curSegment.offset, curSegment.length);
			}
		}
		
		//XXX: close(here.ptr)
		map(child, here.ptr, cast(ubyte*)virtAddress, AccessMode.Writable|AccessMode.AllocOnAccess); 

		return true;
	}	
}
