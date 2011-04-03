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

import user.environment;
import Syscall = user.syscall;

struct Loader {
	static:
	
	ubyte[] load(ubyte[] binary, ubyte[] newgib = null){
		if(newgib is null){
			newgib = 
				Syscall.create(findFreeSegment!(false), oneGB, 
											 AccessMode.Writable|AccessMode.AllocOnAccess);  
		}

		if(Elf.isValid(binary.ptr)){
			loadElf(binary, newgib);
		}else{
			loadFlat(binary, newgib);
		}

		return newgib;
	}

private:
	void loadFlat(ubyte[] binary, ubyte[] newgib) {
		memcpy(cast(void*)newgib.ptr, cast(void*)binary.ptr, binary.length);

		ulong* size = cast(ulong*)newgib.ptr;
		*size = binary.length; // -8?
	}


	// This function will load an executable from a module, if it can.
	void loadElf(ubyte[] binary, ubyte[] newgib) {
		ubyte* binaryAddr = binary.ptr;

		void* entryAddress = Elf.getentry(binaryAddr);
		void* physAddress = Elf.getphysaddr(binaryAddr);
		void* virtAddress = Elf.getvirtaddr(binaryAddr);

		assert(virtAddress == cast(void*)oneGB);
		assert(physAddress == cast(void*)oneGB);
		assert(entryAddress == (cast(void*)oneGB + 16));

		Segment curSegment;
		uint numSegments = Elf.segmentCount(binaryAddr);
		
		for(uint i; i < numSegments; i++) {
			curSegment = Elf.segment(binaryAddr, i);

			//XXX: if there is > one non-empty program segment, this will fail
			if(curSegment.length){
				// Copy segment
				memcpy(newgib.ptr,
							 binaryAddr + curSegment.offset,
							 curSegment.length);

				// Convention is that first 8 bytes store the length.
				// Required for messageInABottle to work.
				ulong* size = cast(ulong*)newgib.ptr;
				*size = curSegment.length; // -8?
			}
		}
	}	
}
