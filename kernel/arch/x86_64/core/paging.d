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

// We need to restart the console driver
import kernel.dev.console;

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
		kprintfln!("in initialize")();
		root = cast(PageLevel4*)Heap.allocPageNoMap();
		kprintfln!("root address: {x}")(root);

		// Initialize the structure. (Zero it)
		*root = PageLevel4.init;
		kprintfln!("Is it broke?")();

		// The current position of the kernel space. All gets appended to this address.
		heapAddress = LinkerScript.kernelVMA;
		kprintfln!("heap Address: {x}")(heapAddress);

		// We need to map the kernel
		kernelAddress = mapRegion(System.kernel.start, System.kernel.length);

		// We now have the kernel mapped
		kernelMapped = true;

		kprintfln!("kernel Address: {x}")(kernelAddress);
		kprintfln!("memory length: {x}")(System.memory.length);

		// Map the system memory
		//mapSystem(cast(void*)0x0, System.memory.length);

		// The page table should be now addressable via a virtual address
		root = cast(PageLevel4*)(cast(ulong)root + cast(ulong)LinkerScript.kernelVMA);

		kprintfln!("root: {x}")(root);

		ulong rootAddr = cast(ulong)root;
		rootAddr -= cast(ulong)LinkerScript.kernelVMA;

		// Restart the console driver to look at the right place
		Console.initialize();

		kprintfln!("root addr: {x}")(rootAddr);
		// Must map
		asm {
			mov RAX, rootAddr;
			mov CR3, RAX;
		}

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

	void translateAddress( void* virtAddress,
							out ulong indexLevel1,
							out ulong indexLevel2,
							out ulong indexLevel3,
							out ulong indexLevel4)
	{
		ulong vAddr = cast(ulong)virtAddress;
		kprintfln!("addr {x}")(virtAddress);

		vAddr >>= 12;
		indexLevel1 = vAddr & 0x1ff;
		vAddr >>= 9;
		indexLevel2 = vAddr & 0x1ff;
		vAddr >>= 9;
		indexLevel3 = vAddr & 0x1ff;
		vAddr >>= 9;
		indexLevel4 = vAddr & 0x1ff;
	}

	ErrorVal mapSystem(void* physAddr, ulong regionLength)
	{
		// Check to make sure we aren't doing this again
		if (systemMapped)
		{
			assert(false, "System RAM already mapped.");
		}

		// The kernel must be mapped before hand
		if (!kernelMapped)
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

		// This region will be located at the current heapAddress
		void* location = heapAddress;

		doHeapMap(physAddr, endAddr);

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


// -- Mapping Functions -- //


	void doHeapMap(void* physAddr, void* endAddr)
	{
		// Do the mapping
		PageLevel3* pl3;
		PageLevel2* pl2;
		PageLevel1* pl1;
		ulong indexL1, indexL2, indexL3, indexL4;

		// Find the initial page
		translateAddress(heapAddress, indexL1, indexL2, indexL3, indexL4);

		kprintfln!("{x} {x} {x} {x}")(indexL4, indexL3, indexL2, indexL1);
		// From there, map the region
		ulong done = 0;
		for ( ; indexL4 < 512 && physAddr < endAddr ; indexL4++ )
		{
			// get the L3 table
			pl3 = root.entries[indexL4].getOrCreateTable();

			for ( ; indexL3 < 512 ; indexL3++ )
			{
				// get the L2 table
				pl2 = pl3.entries[indexL3].getOrCreateTable();

				for ( ; indexL2 < 512 ; indexL2++ )
				{
					// get the L1 table
					pl1 = pl2.entries[indexL2].getOrCreateTable();

					for ( ; indexL1 < 512 ; indexL1++ )
					{
						// set the address
						pl1.entries[indexL1].setAddress(physAddr);

						pl1.entries[indexL1].present = 1;
						pl1.entries[indexL1].rw = 1;
						pl1.entries[indexL1].pat = 1;

						physAddr += VirtualMemory.PAGESIZE;
						done += VirtualMemory.PAGESIZE;

						if (physAddr >= endAddr)
						{
							indexL2 = 512;
							indexL3 = 512;
							break;
						}
					}

					indexL1 = 0;
				}

				indexL2 = 0;
			}

			indexL3 = 0;
		}

		if (indexL4 >= 512)
		{
			// we have depleted our table!
			assert(false, "Virtual Memory depleted");
		}

		// Recalculate the region length
		ulong regionLength = cast(ulong)endAddr - cast(ulong)physAddr;

		// Relocate heap address
		heapAddress += regionLength;
	}


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
			void* tableAddr = getAddress();
			if (tableAddr is null)
			{
				return null;
			}

			return cast(T*)(cast(ulong)tableAddr + systemAddress);
		}

		// This will return the pointer to a newly allocated table at that index, if one does not exist.
		T* getOrCreateTable()
		{
			T* table = getTable();

			if (table is null)
			{
				// allocate table
				void* tableAddr = Heap.allocPageNoMap();

				ulong addr = cast(ulong)tableAddr;
				addr >>= 12;

				// set this table within the page table
				address = addr;
				present = 1;
				rw = 1;

				tableAddr = cast(void*)(cast(ulong)tableAddr + systemAddress);

				// set the table
				table = cast(T*)tableAddr;

				// clear the table
				*table = T.init;
			}

			return table;
		}

		void setUserAccess()
		{
			us = 1;
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

		// This will map the physical address to this page
		void setAddress(void* physAddr)
		{
			ulong addr = cast(ulong)physAddr;
			addr >>= 12;

			address = addr;
		}

		void setUserAccess()
		{
			us = 1;
		}
	}

	// Each of the following will use the entries above to define the page table.
	align(1) struct PageLevel4
	{
		SecondaryPTE!(PageLevel3)[512] entries;

		// Given a virtual address, this convenience function will set up the tables
		// necessary to map a physical address to this virtual address.
		void getOrCreateTranslation(in void* virtAddr,
									out PageLevel3* pl3,
									out PageLevel2* pl2,
									out PageLevel1* pl1,
									out ulong indexLevel1,
									out ulong indexLevel2,
									out ulong indexLevel3,
									out ulong indexLevel4)
		{
			ulong vAddr = cast(ulong)virtAddr;

			vAddr >>= 12;
			indexLevel1 = vAddr & 0x1ff;
			vAddr >>= 9;
			indexLevel2 = vAddr & 0x1ff;
			vAddr >>= 9;
			indexLevel3 = vAddr & 0x1ff;
			vAddr >>= 9;
			indexLevel4 = vAddr & 0x1ff;

			pl3 = entries[indexLevel4].getOrCreateTable();
			pl2 = pl3.entries[indexLevel3].getOrCreateTable();
			pl1 = pl2.entries[indexLevel2].getOrCreateTable();
		}
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
