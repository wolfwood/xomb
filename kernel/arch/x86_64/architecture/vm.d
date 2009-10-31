/*
 * vm.d
 *
 * This file implements the virtual memory interface needed by the
 * architecture dependent bridge
 *
 */

module architecture.vm;

// All of the paging calls
import kernel.arch.x86_64.core.paging;

// Normal kernel modules
import kernel.core.error;

struct VirtualMemory
{
static:
public:

	ErrorVal initialize() {
		// Install Virtual Memory and Paging
		return Paging.initialize();
	}

	ErrorVal install() {
		return Paging.install();
	}

	// Allocs a new gib
	void* allocGib() {
		return Paging.allocGib();
	}

	// This function will take the "gib" specified and map it to the gib determined by "to".
	ErrorVal mapGib(void* gib, void* to) {
		return Paging.mapGib(gib, to);
	}

	ErrorVal mapRegion(void* gib, void* physAddr, ulong regionLength) {
		return Paging.mapRegion(gib, physAddr, regionLength);
	}

	// The page size we are using
	uint getPageSize() {
		return Paging.PAGESIZE;
	}

	// This function will translate a virtual address to a physical address.
	void* translate(void* address)
	{
		return Paging.translateAddress(address);
	}

	// This function will map a region to the region space starting at
	// physAdd across a length of regionLength.
	void* mapRegion(void* physAddr, ulong regionLength)
	{
		return Paging.mapRegion(physAddr, regionLength);
	}

	//
	void* mapKernelPage(void* physAddr)
	{
		return Paging.mapRegion(physAddr, 4096);
	}

	// This function will map a single page at the specified physical address
	// to the specifed virtual address.
	ErrorVal mapPage(void* physAddr, void* virtAddr)
	{
		return ErrorVal.Success;
	}

	// This function will map a range of data located at the physical
	// address across a range of a specifed length to the virtual
	// region starting at virtual address.
	ErrorVal mapRange(void* physAddr, ulong rangeLength, void* virtAddr)
	{
		return ErrorVal.Success;
	}

	// This function will unmap a page at the virtual address specified.
	ErrorVal unmapPage(void* virtAddr)
	{
		return ErrorVal.Success;
	}

	// This function will unmap a range of data. Give the length in bytes.
	ErrorVal unmapRange(void* virtAddr, ulong rangeLength)
	{
		return ErrorVal.Success;
	}

private:

}
