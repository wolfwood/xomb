/*
 * bitmap.d
 *
 * This is a bitmap based page allocation scheme. It does nothing special
 * and simply allocates the first free page it finds.
 *
 */

module kernel.mem.bitmap;

// Import system info to get info about RAM
import kernel.system.info;

// Import the parent allocator
import kernel.mem.pageallocator;

// Import kernel foo
import kernel.core.error;
import kernel.core.log;
import kernel.core.kprintf;

// Import arch foo
import architecture.vm;


ErrorVal initialize() {

	// Calculate the number of pages.
	totalPages = System.memory.length / VirtualMemory.pagesize();

	// Get a gib for the page allocator
	bitmapGib = cast(ulong*)VirtualMemory.createSegment(VirtualMemory.findFreeSegment(), AccessMode.Writable|AccessMode.AllocOnAccess).ptr;

	// Calculate how much we need for the bitmap.
	// 8 bits per byte, 8 bytes for ulong.
	// We can store the availability of a page for 64 pages per ulong.

	const uint bitsPerPage = 4096 * 8;

	bitmapPages = totalPages / bitsPerPage;
	if ((totalPages % bitsPerPage) > 0) { bitmapPages++; }

	ulong bitmapSize = bitmapPages * VirtualMemory.pagesize();
	// Zero out bitmap initially
	for (size_t i = 0; i < bitmapSize; i++) {
		bitmapGib[i] = 0;
	}

	kprintfln!("BITMAP CREATED")();

	// Set up the bitmap for the regions used by the system.

	// The kernel...
	markOffRegion(System.kernel.start, System.kernel.length);

	// The initial page allocation (before the data structures were created)...
	markOffRegion(cast(void*)PageAllocator._start, (cast(ulong)PageAllocator._curpos - cast(ulong)PageAllocator._start));

	// Each other region
	for(uint i; i < System.numRegions; i++) {
		//kprintfln!("Region: start:0x{x} length:0x{x}")(System.regionInfo[i].start, System.regionInfo[i].length);
		markOffRegion(System.regionInfo[i].start, System.regionInfo[i].length);
	}

	// Each module as well
	for (uint i; i < System.numModules; i++) {
		//kprintfln!("Module: start:0x{x} length:0x{x}")(System.moduleInfo[i].start, System.moduleInfo[i].length);
		markOffRegion(System.moduleInfo[i].start, System.moduleInfo[i].length);
	}

	kprintfln!("Success : ")();
	// It succeeded!
	return ErrorVal.Success;
}

ErrorVal reportCore() {
	return ErrorVal.Success;
}

PhysicalAddress allocPage() {
	return allocPage(null);
}

PhysicalAddress allocPage(void * virtAddr) {
	// Find a page
	ulong index = findPage(virtAddr);

	if (index == 0xffffffffffffffffUL) {
		return null;
	}

	// Return the address
	return cast(PhysicalAddress)(index * VirtualMemory.pagesize());
}

ErrorVal freePage(PhysicalAddress address) {
	// Find the page index
	ulong pageIndex = cast(ulong)address;

	// Is this address a valid result of allocPage?
	if ((pageIndex % VirtualMemory.pagesize()) > 0) {
		// Should be aligned, otherwise, what to do here is ambiguious.
		return ErrorVal.Fail;
	}

	// Get the page index
	pageIndex /= VirtualMemory.pagesize();

	// Is this a valid page?
	if (pageIndex >= totalPages) {
		return ErrorVal.Fail;
	}

	// Reset the index at this address
	ulong ptrIndex = pageIndex / 64;
	ulong subIndex = pageIndex % 64;

	// Reset the bit
	bitmapGib[ptrIndex] &= ~(1 << subIndex);

	// All is well
	return ErrorVal.Success;
}

uint length() {
	return bitmapPages * VirtualMemory.pagesize();
}

ubyte* start() {
	return cast(ubyte*)null;
}

ubyte* virtualStart() {
	return cast(ubyte*)bitmapGib;
}

void virtualStart(void* newAddr) {
}

package {
	ulong totalPages;

	// The total number of pages for the bitmap
	ulong bitmapPages;

//	ulong* bitmapPhys;

	ulong* bitmapGib;

	// A helper function to mark off a range of memory
	void markOffRegion(void* start, ulong length) {
		// When aligning to a page, floor the start, ceiling the end

		// Get the first pageIndex
		ulong startAddr, endAddr;

		// Get the logical range
		startAddr = cast(ulong)start;
		endAddr = startAddr + length;
		startAddr -= startAddr % VirtualMemory.pagesize();
		if ((endAddr % VirtualMemory.pagesize())>0) {
			endAddr += VirtualMemory.pagesize() - (endAddr % VirtualMemory.pagesize());
		}

		// startAddr is the start address of the region aligned to a page
		// endAddr is the end address of the region aligned to a page

		// Now, we will get the page indices and mark off each page
		ulong pageIndex = startAddr / VirtualMemory.pagesize();
		ulong maxIndex = (endAddr - startAddr) / VirtualMemory.pagesize();
		maxIndex += pageIndex;

		for(; pageIndex<maxIndex; pageIndex++) {
			markOffPage(pageIndex);
		}
	}

	void markOffPage(ulong pageIndex) {
		// Go to the specific ulong
		// Set the corresponding bit

		if (pageIndex >= totalPages) {
			return;
		}

		ulong byteNumber = pageIndex / 64;
		ulong bitNumber = pageIndex % 64;

		bitmapGib[byteNumber] |= (1 << bitNumber);
	}

	// Returns the page index of a free page
	ulong findPage(void * virtAddr) {
		ulong* curPtr = bitmapGib;
		ulong curIndex = 0;

		while(true) {
			// this would mean that there is a 0 in there somewhere
			if (*curPtr < 0xffffffffffffffffUL) {
				// look for the 0
				ulong tmpVal = *curPtr;
				ulong subIndex = curIndex;

				for (uint b; b < 64; b++) {
					if((tmpVal & 0x1) == 0) {
						if (subIndex < totalPages) {
							// mark it off as used
							*curPtr |= cast(ulong)(1UL << b);

							// return the page index
							return subIndex;
						}
						else {
							return 0xffffffffffffffffUL;
						}
					}
					else {
						tmpVal >>= 1;
						subIndex++;
					}
				}

				// Shouldn't get here... the world will end
				return 0xffffffffffffffffUL;
			}

			curIndex += 64;
			if (curIndex >= totalPages) {
				return 0xffffffffffffffffUL;
			}
			curPtr++;
		}

		return 0xffffffffffffffffUL;
	}

}
