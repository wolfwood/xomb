/*
 * heap.d
 *
 * This module implements the kernel heap page allocator.
 *
 */

module kernel.mem.heap;

// Import system info to get info about RAM
import kernel.system.info;

// Import architecture dependent foo
import architecture;

// Import kernel foo
import kernel.core.kprintf;
import kernel.core.log;
import kernel.core.error;

struct Heap
{
static:
public:

	// Needs to be called by the architecture
	ErrorVal initialize(void* location)
	{
		kprintfln!("location: {x}")(location);
		// We do not want to reinitialize this module.
		if (initialized)
		{
			return ErrorVal.Fail;
		}

		// The module has been initialized.
		initialized = true;

		// Calculate the number of pages.
		totalPages = System.memory.length / VirtualMemory.getPageSize();

		// Find the first free page, and set up the bitmap.
		bitmap = cast(ulong*)location;

		// Align the bitmap address to the page size (ceiling)
		ulong padding = cast(ulong)bitmap % VirtualMemory.getPageSize();
		if (padding != 0) { padding = VirtualMemory.getPageSize() - padding; }
		bitmap += padding;

		// Calculate how much we need for the bitmap.
		// 8 bits per byte, 8 bytes for ulong.
		// We can store the availability of a page for 64 pages per ulong.

		bitmapPages = totalPages / 64;
		if ((totalPages % 64) > 0) { bitmapPages++; }

		kprintfln!("bitmap: {x} for {x} pages : totalpages {x}")(bitmap, bitmapPages, totalPages);

		// Set up the bitmap for the regions used by the system.

		// The kernel...
		markOffRegion(System.kernel.start, System.kernel.length);

		// Each other region
		for(uint i=0; i<System.numRegions; i++)
		{
			kprintfln!("Region: start:0x{x} length:0x{x}")(System.regionInfo[i].start, System.regionInfo[i].length);
			markOffRegion(System.regionInfo[i].start, System.regionInfo[i].length);
		}

		kprintfln!("Success")();

		// It succeeded!
		return ErrorVal.Success;
	}

	// This will allocate a page and return a physical address and will
	// not attempt to map it into virtual memory.
	void* allocPageNoMap()
	{
		// Find a page
		ulong index = findPage();

		// Return the address
		return cast(void*)(index * VirtualMemory.getPageSize());
	}

	// This will allocate a page, and return the virtual address while
	// coordinating with the VirtualMemory module.
	void* allocPage()
	{
		// Find a page
		ulong index = findPage();

		// compute physical address
		void* address = cast(void*)(index * VirtualMemory.getPageSize());

		// map in the region
		return VirtualMemory.mapKernelPage(address);
	}

	// This will free an allocated page, if it is allowed.
	ErrorVal freePage(void* address)
	{
		// Find the page index
		ulong pageIndex = cast(ulong)address;

		// Is this address a valid result of allocPage?
		if ((pageIndex % VirtualMemory.getPageSize()) > 0)
		{
			// Should be aligned, otherwise, what to do here is ambiguious.
			return ErrorVal.Fail;
		}

		// Get the page index
		pageIndex /= VirtualMemory.getPageSize();

		// Is this a valid page?
		if (pageIndex >= totalPages)
		{
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

private:

	// Whether or not this module has been initialized
	bool initialized;

	// The total number of pages in RAM
	ulong totalPages;

	// The total number of pages for the bitmap
	ulong bitmapPages;

	ulong* bitmap;

	// A helper function to mark off a range of memory
	void markOffRegion(void* start, ulong length)
	{
		// When aligning to a page, floor the start, ceiling the end

		// Get the first pageIndex
		ulong startAddr, endAddr;

		// Get the logical range
		startAddr = cast(ulong)start;
		endAddr = startAddr + length;
		startAddr -= startAddr % VirtualMemory.getPageSize();
		if ((endAddr % VirtualMemory.getPageSize())>0)
		{
			endAddr += VirtualMemory.getPageSize() - (endAddr % VirtualMemory.getPageSize());
		}

		// startAddr is the start address of the region aligned to a page
		// endAddr is the end address of the region aligned to a page

		// Now, we will get the page indices and mark off each page
		ulong pageIndex = startAddr / VirtualMemory.getPageSize();
		ulong maxIndex = (endAddr - startAddr) / VirtualMemory.getPageSize();
		maxIndex += pageIndex;

		for(; pageIndex<maxIndex; pageIndex++)
		{
			markOffPage(pageIndex);
		}
	}

	void markOffPage(ulong pageIndex)
	{
		// Go to the specific ulong
		// Set the corresponding bit

		if (pageIndex >= totalPages)
		{
			return;
		}

		ulong byteNumber = pageIndex / 64;
		ulong bitNumber = pageIndex % 64;

		bitmap[byteNumber] |= (1 << bitNumber);
	}

	// Returns the page index of a free page
	ulong findPage()
	{
		ulong* curPtr = bitmap;
		ulong curIndex = 0;
		ulong subIndex = 0;

		while(true)
		{
			// this would mean that there is a 0 in there somewhere
			if (*curPtr < 0xffffffffffffffffUL)
			{
				// look for the 0
				subIndex = 0;

				ulong tmpVal = *curPtr;

				if((tmpVal & 0x1) == 0)
				{
					if (curIndex < totalPages)
					{
						// mark it off as used
						*curPtr |= (1 << subIndex);

						// return the page index
						return curIndex;
					}
					else
					{
						return 0xffffffffffffffffUL;
					}
				}
				else
				{
					tmpVal >>= 1;
					curIndex++;
					subIndex++;
				}
			}

			curIndex += 64;
			if (curIndex >= totalPages)
			{
				return 0xffffffffffffffffUL;
			}
			curPtr++;
		}

		return 0xffffffffffffffffUL;
	}
}
