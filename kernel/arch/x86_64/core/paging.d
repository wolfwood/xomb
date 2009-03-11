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

// Import the heap allocator, so we can allocate memory
import kernel.mem.heap;

// Import information about the system
// (we need to know where the kernel is)
import kernel.system.info;

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

		// We need to map the kernel

		// Tell the system where RAM will be mapped (after the kernel)
		System.memory.virtualStart = cast(void*)0x0;

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

private:


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
