/*
 * paging.d
 *
 * This module implements the structures and logic associated with paging.
 *
 */

module kernel.arch.x86_64.core.paging;

// Import common kernel stuff
import kernel.core.util;
import kernel.core.error;
import kernel.core.kprintf;

// Import the heap allocator, so we can allocate memory
import kernel.mem.heap;

// Import some arch-dependent modules
import kernel.arch.x86_64.linker;	// want linker info
import kernel.arch.x86_64.vm;		// want page size

// Import information about the system
// (we need to know where the kernel is)
import kernel.system.info;

// Kernel Memory Map:
//
// [0xFFFF800000000000]
//   - kernel
//   - RAM (page table entry map)
//   - kheap
//      - devices
//      - misc

struct Paging
{
static:
public:

	// This function will initialize paging and install a core page table.
	ErrorVal initialize()
	{
		// Create a new page table.
		root = cast(PageLevel4*)Heap.allocPageNoMap();

		// Initialize the structure. (Zero it)
		*root = PageLevel4.init;

		// The current position of the kernel space. All gets appended to this address.
		heapAddress = LinkerScript.kernelVMA;

		// We need to map the kernel (starting from 0x0
		kernelAddress = mapRegion(cast(void*)0x0, cast(ulong)(System.kernel.length + System.kernel.start));

		// We now have the kernel mapped
		kernelMapped = true;

		kprintfln!("kernel Address: {x}")(kernelAddress);

		// All is well.
		return ErrorVal.Success;
	}

	// This function will get the physical address that is mapped from the
	// specified virtual address.
	void* translateAddress(void* virtAddress)
	{
		ulong vAddr = cast(ulong)virtAddress;

		vAddr >>= 12;
		uint indexLevel1 = vAddr & 0x1ff;
		vAddr >>= 9;
		uint indexLevel2 = vAddr & 0x1ff;
		vAddr >>= 9;
		uint indexLevel3 = vAddr & 0x1ff;
		vAddr >>= 9;
		uint indexLevel4 = vAddr & 0x1ff;

		return root.entries[indexLevel4].getTable()
				.entries[indexLevel3].getTable()
				.entries[indexLevel2].getTable()
				.entries[indexLevel1].getAddress();
	}

	ErrorVal mapSystem(void* physAddr, ulong regionLength)
	{
		// Check to make sure we aren't doing this again
		if (systemMapped)
		{
			assert(false, "System RAM already mapped.");
		}

		// The kernel must be mapped before hand
		if (kernelMapped)
		{
			assert(false, "The Kernel mapping has yet to be done.");
		}

		// heapAddress should be valid from the kernel mapping
		systemAddress = mapRegion(physAddr, regionLength);

		// Tell the system where RAM will be mapped (after the kernel)
		System.memory.virtualStart = cast(void*)systemAddress;

		// Consider the system mapping done, so we don't do it again
		systemMapped = true;

		// All is well
		return ErrorVal.Success;
	}

	// Using heapAddress, this will add a region to the kernel space
	// It returns the virtual address to this region.
	void* mapRegion(void* physAddr, ulong regionLength)
	{
		// Sanitize inputs

		// physAddr should be floored to the page boundary
		// regionLength should be ceilinged to the page boundary
		ulong curPhysAddr = cast(ulong)physAddr;
		regionLength += (curPhysAddr % VirtualMemory.PAGESIZE);
		curPhysAddr -= (curPhysAddr % VirtualMemory.PAGESIZE);

		// Set the new starting address
		physAddr = cast(void*)curPhysAddr;

		// Get the end address
		curPhysAddr += regionLength;

		// Align the end address
		if ((curPhysAddr % VirtualMemory.PAGESIZE) > 0)
		{
			curPhysAddr += VirtualMemory.PAGESIZE - (curPhysAddr % VirtualMemory.PAGESIZE);
		}

		// Define the end address
		void* endAddr = cast(void*)curPhysAddr;

		// Recalculate the region length
		regionLength = cast(ulong)endAddr - cast(ulong)physAddr;

		// Do the mapping
		// TODO: this

		// This region will be located at the current heapAddress
		void* location = heapAddress;

		// Relocate heap address
		heapAddress += regionLength;

		// Return the position of this region
		return location;
	}

private:


// -- Flags -- //


	bool systemMapped;
	bool kernelMapped;


// -- Positions -- //


	void* systemAddress;
	void* kernelAddress;
	void* heapAddress;


// -- Main Page Table -- //


	PageLevel4* root;


// -- Structures -- //


	// The x86 implements a four level page table.
	// We use the 4KB page size hierarchy

	// The levels are defined here, many are the same but they need
	// to be able to be typed differently so we don't make a stupid
	// mistake.

	align(1) struct SecondaryPTE(T)
	{
		ulong pml;

		mixin (Bitfield!(pml,
			"present", 1,
			"rw", 1,
			"us", 1,
			"pwt", 1,
			"pcd", 1,
			"a", 1,
			"ign", 1,
			"mbz", 2,
			"avl", 3,
			"address", 41,
			"available", 10,
			"nx", 1));

		// This will give the physical address associated with this table.
		void* getAddress()
		{
			ulong addr = address();
			addr <<= 12;

			return cast(void*)addr;
		}

		// This will return the pointer to the table at that index.
		T* getTable()
		{
			return cast(T*)getAddress();
		}
	}

	align(1) struct PrimaryPTE
	{
		ulong pml;

		mixin (Bitfield!(pml,
			"present", 1,
			"rw", 1,
			"us", 1,
			"pwt", 1,
			"pcd", 1,
			"a", 1,
			"d", 1,
			"pat", 1,
			"g", 1,
			"avl", 3,
			"address", 41,
			"available", 10,
			"nx", 1));

		// This will retrieve the physical address from the field.
		void* getAddress()
		{
			ulong addr = address();
			addr <<= 12;

			return cast(void*)addr;
		}
	}

	// Each of the following will use the entries above to define the page table.
	align(1) struct PageLevel4
	{
		SecondaryPTE!(PageLevel3)[512] entries;
	}

	align(1) struct PageLevel3
	{
		SecondaryPTE!(PageLevel2)[512] entries;
	}

	align(1) struct PageLevel2
	{
		SecondaryPTE!(PageLevel1)[512] entries;
	}

	align(1) struct PageLevel1
	{
		PrimaryPTE[512] entries;
	}

}
