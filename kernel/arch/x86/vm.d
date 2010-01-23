/*
 * vm.d
 *
 * This file implements the virtual memory interface needed by the
 * architecture dependent bridge
 *
 */

module kernel.arch.x86.vm;

// Import the PageTable
// TODO: all of this

// All of the paging calls
// TODO: all of this

// Normal kernel modules
import kernel.core.error;

struct VirtualMemory
{
static:
public:

	// The page size we are using
	const auto PAGESIZE = 4096;

	// This function will translate a virtual address to a physical address.
	void* translate(void* address)
	{
		return null;
	}

	// This defines the system memory. physAddr is the starting address
	// which is probably 0x0 and then the length of RAM.
	ErrorVal mapSystem(void* physAddr, ulong systemLength)
	{
		return ErrorVal.Success;
	}

	// This function will map a region to the region space starting at
	// physAdd across a length of regionLength.
	void* mapRegion(void* physAddr, ulong regionLength)
	{
		return null;
	}

	//
	void* mapKernelPage(void* physAddr)
	{
		return null;
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
