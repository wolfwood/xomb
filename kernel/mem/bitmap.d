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

// Import kernel foo
import kernel.core.error;
import kernel.core.log;
import kernel.core.error;

// Import arch foo
import architecture.vm;

ErrorVal initialize() {

	// Calculate the number of pages.
	totalPages = System.memory.length / VirtualMemory.getPageSize();

	// Find the first free page, and set up the bitmap.

	// First, start out with the address at the end of the kernel
	bitmap = cast(ulong*)(System.kernel.start + System.kernel.length);

	// Align the bitmap address to the page size (ceiling)
	ulong padding = cast(ulong)bitmap % VirtualMemory.getPageSize();
	if (padding != 0) { padding = VirtualMemory.getPageSize() - padding; }
	bitmap += padding;

	// Calculate how much we need for the bitmap.
	// 8 bits per byte, 8 bytes for ulong.
	// We can store the availability of a page for 64 pages per ulong.

	bitmapPages = totalPages / 64;
	if ((totalPages % 64) > 0) { bitmapPages++; }

	ulong bitmapSize = bitmapPages * VirtualMemory.getPageSize();
	ulong* bitmapEdge = bitmap + (bitmapSize >> 3);

	//kprintfln!("bitmap: {x} for {x} pages : totalpages {x}")(bitmap, bitmapPages, totalPages);

	// Now, check to see if the bitmap can fit here
	bool bitmapOk = false;
	while(!bitmapOk) {
		uint i;
		for (i = 0; i < System.numRegions; i++) {
			ulong* regionAddr = cast(ulong*)System.regionInfo[i].start;
			ulong* regionEdge = cast(ulong*)(System.regionInfo[i].start + System.regionInfo[i].length);
			if ((bitmap < regionEdge) && (bitmapEdge > regionAddr)) {
				// overlap...
				// move bitmap
				//kprintfln!("Region Overlaps! Moving Heap")();
				bitmap = regionEdge;
				// align to page size
				bitmap = cast(ulong*)(cast(ubyte*)bitmap + VirtualMemory.getPageSize() - (cast(ulong)bitmap % VirtualMemory.getPageSize()));
				bitmapEdge = bitmap + (bitmapSize >> 3);
				break;
			}
		}
		if (i < System.numRegions) {
			continue;
		}

		for (i = 0; i < System.numModules; i++) {
			ulong* regionAddr = cast(ulong*)System.moduleInfo[i].start;
			ulong* regionEdge = cast(ulong*)(System.moduleInfo[i].start + System.moduleInfo[i].length);
			if ((bitmap < regionEdge) && (bitmapEdge > regionAddr)) {
				// overlap...
				// move bitmap
				//kprintfln!("Module Overlaps! Moving Heap")();
				bitmap = regionEdge;
				// align to page size
				bitmap = cast(ulong*)(cast(ubyte*)bitmap + VirtualMemory.getPageSize() - (cast(ulong)bitmap % VirtualMemory.getPageSize()));
				bitmapEdge = bitmap + (bitmapSize >> 3);
				//kprintfln!("(NEW) Bitmap location: {x}")(bitmap);
				break;
			}
		}
		if (i == System.numModules) {
			bitmapOk = true;
		}
	}
	//kprintfln!("Bitmap location: {x}")(bitmap);

	// Set up the bitmap for the regions used by the system.

	// The kernel...
	markOffRegion(System.kernel.start, System.kernel.length);

	// The bitmap...
	markOffRegion(cast(void*)bitmap, bitmapSize);

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

	// Virtual Address for the heap is relative to the kernel
	bitmapPhys = bitmap;
	//	kprintfln!("findPage: {x}")(allocPageNoMap());
	//kprintfln!("findPage: {x}")(findPage());
	//		kprintfln!("findPage: {x}")(findPage());
	//		kprintfln!("findPage: {x}")(findPage());
	//kprintfln!("Success : {x}")(bitmap);
	// It succeeded!
	return ErrorVal.Success;
}

void* allocPage() {
	// Find a page
	ulong index = findPage();

	if (index == 0xffffffffffffffffUL) {
		return null;
	}

	// Return the address
	return cast(void*)(index * VirtualMemory.getPageSize());
}

ErrorVal freePage(void* address) {
	// Find the page index
	ulong pageIndex = cast(ulong)address;

	// Is this address a valid result of allocPage?
	if ((pageIndex % VirtualMemory.getPageSize()) > 0) {
		// Should be aligned, otherwise, what to do here is ambiguious.
		return ErrorVal.Fail;
	}

	// Get the page index
	pageIndex /= VirtualMemory.getPageSize();

	// Is this a valid page?
	if (pageIndex >= totalPages) {
		return ErrorVal.Fail;
	}

	// Reset the index at this address
	ulong ptrIndex = pageIndex / 64;
	ulong subIndex = pageIndex % 64;

	// Reset the bit
	bitmap[ptrIndex] &= ~(1 << subIndex);

	// All is well
	return ErrorVal.Success;
}

uint length() {
	return bitmapPages * VirtualMemory.getPageSize();
}

ubyte* start() {
	return cast(ubyte*)bitmapPhys;
}

ubyte* virtualStart() {
	return cast(ubyte*)bitmap;
}

void virtualStart(void* newAddr) {
	bitmap = cast(ulong*)newAddr;
}

private {
	ulong totalPages;

	// The total number of pages for the bitmap
	ulong bitmapPages;

	ulong* bitmap;
	ulong* bitmapPhys;

	// A helper function to mark off a range of memory
	void markOffRegion(void* start, ulong length) {
		// When aligning to a page, floor the start, ceiling the end

		// Get the first pageIndex
		ulong startAddr, endAddr;

		// Get the logical range
		startAddr = cast(ulong)start;
		endAddr = startAddr + length;
		startAddr -= startAddr % VirtualMemory.getPageSize();
		if ((endAddr % VirtualMemory.getPageSize())>0) {
			endAddr += VirtualMemory.getPageSize() - (endAddr % VirtualMemory.getPageSize());
		}

		// startAddr is the start address of the region aligned to a page
		// endAddr is the end address of the region aligned to a page

		// Now, we will get the page indices and mark off each page
		ulong pageIndex = startAddr / VirtualMemory.getPageSize();
		ulong maxIndex = (endAddr - startAddr) / VirtualMemory.getPageSize();
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

		bitmap[byteNumber] |= (1 << bitNumber);
	}

	// Returns the page index of a free page
	ulong findPage() {
		ulong* curPtr = bitmap;
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
