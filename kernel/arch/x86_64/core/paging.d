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
import kernel.mem.pageallocator;
import kernel.mem.heap;
import kernel.mem.giballocator;

// Import some arch-dependent modules
import kernel.arch.x86_64.linker;	// want linker info

import kernel.arch.x86_64.core.idt;

// Import information about the system
// (we need to know where the kernel is)
import kernel.system.info;

// We need to restart the console driver
import kernel.dev.console;

import architecture.mutex;

class Paging {
static:

	// The page size we are using
	const auto PAGESIZE = 4096;

	// This function will initialize paging and install a core page table.
	ErrorVal initialize() {
		// Create a new page table.
		root = cast(PageLevel4*)PageAllocator.allocPage();
		PageLevel3* pl3 = cast(PageLevel3*)PageAllocator.allocPage();
		PageLevel2* pl2 = cast(PageLevel2*)PageAllocator.allocPage();

		//kprintfln!("root: {} pl3: {} pl2: {}")(root, pl3, pl2);

		// Initialize the structure. (Zero it)
		*root = PageLevel4.init;
		*pl3 = PageLevel3.init;
		*pl2 = PageLevel2.init;

		// Map entries 511 to the PML4
		root.entries[511].pml = cast(ulong)root;
		root.entries[511].present = 1;
		root.entries[511].rw = 1;
		pl3.entries[511].pml = cast(ulong)root;
		pl3.entries[511].present = 1;
		pl3.entries[511].rw = 1;
		pl2.entries[511].pml = cast(ulong)root;
		pl2.entries[511].present = 1;
		pl2.entries[511].rw = 1;

		// Map entry 510 to the next level
		root.entries[510].pml = cast(ulong)pl3;
		root.entries[510].present = 1;
		root.entries[510].rw = 1;
		pl3.entries[510].pml = cast(ulong)pl2;
		pl3.entries[510].present = 1;
		pl3.entries[510].rw = 1;

		// The current position of the kernel space. All gets appended to this address.
		heapAddress = LinkerScript.kernelVMA;

		// We need to map the kernel
		kernelAddress = heapAddress;

		//kprintfln!("About to map kernel")();
		mapRegion(System.kernel.start, System.kernel.length);

		void* bitmapLocation = heapAddress;
		
		// The first gib for the kernel
		nextGib++;

		// Assign the page fault handler
		IDT.assignHandler(&faultHandler, 14);

		// We now have the kernel mapped
		kernelMapped = true;

		// Save the physical address for later
		rootPhysical = cast(void*)root;

		// This is the virtual address for the page table
		root = cast(PageLevel4*)0xFFFFFFFF_FFFFF000;

		// All is well.
		return ErrorVal.Success;
	}

	void faultHandler(InterruptStack* stack) {
		ulong cr2;

		asm {
			mov RAX, CR2;
			mov cr2, RAX;
		}

		void* addr = cast(void*)cr2;

		if (stack.rip < 0xf_0000_0000_0000) {
			kprintfln!("User Mode Page Fault {x}")(stack.rip);
			kprintfln!("CR2: {}")(addr);
		}

		ulong indexL4, indexL3, indexL2, indexL1;
		translateAddress(addr, indexL1, indexL2, indexL3, indexL4);

		// check for gib status
		PageLevel3* pl3 = root.getTable(indexL4);
		if (pl3 is null) {
			// NOT AVAILABLE
		}
		else {
			PageLevel2* pl2 = pl3.getTable(indexL3);
			if (pl2 is null) {
				// NOT AVAILABLE (FOR SOME REASON)
				kprintfln!("CR2 {}")(addr);
			}
			else {
//				kprintfln!("Gib Available")();

				// Allocate Page
				addr = cast(void*)(cast(ulong)addr & 0xffff_ffff_ffff_f000UL);

//				kprintfln!("Allocating a page")();
				void* page = PageAllocator.allocPage();

				mapRegion(null, page, PAGESIZE, addr, true);
			}
		}
	}

	ErrorVal install() {
		ulong rootAddr = cast(ulong)rootPhysical;
		asm {
			mov RAX, rootAddr;
			mov CR3, RAX;
		}
		return ErrorVal.Success;
	}

	// This function will get the physical address that is mapped from the
	// specified virtual address.
	void* translateAddress(void* virtAddress) {
		ulong vAddr = cast(ulong)virtAddress;

		vAddr >>= 12;
		uint indexLevel1 = vAddr & 0x1ff;
		vAddr >>= 9;
		uint indexLevel2 = vAddr & 0x1ff;
		vAddr >>= 9;
		uint indexLevel3 = vAddr & 0x1ff;
		vAddr >>= 9;
		uint indexLevel4 = vAddr & 0x1ff;

		return root.getTable(indexLevel4).getTable(indexLevel3).getTable(indexLevel2).physicalAddress(indexLevel1);
	}

	void translateAddress( void* virtAddress,
							out ulong indexLevel1,
							out ulong indexLevel2,
							out ulong indexLevel3,
							out ulong indexLevel4) {
		ulong vAddr = cast(ulong)virtAddress;

		vAddr >>= 12;
		indexLevel1 = vAddr & 0x1ff;
		vAddr >>= 9;
		indexLevel2 = vAddr & 0x1ff;
		vAddr >>= 9;
		indexLevel3 = vAddr & 0x1ff;
		vAddr >>= 9;
		indexLevel4 = vAddr & 0x1ff;
	}

	Mutex pagingLock;

	const ulong MAX_USER_GIB = (256 * 512);
	synchronized void* allocUserGib(ulong gibIndex) {
		if (gibIndex > MAX_USER_GIB) {
			return cast(void*)-1;
		}

		pagingLock.lock();
		// Calculate address
		void* gibAddr = cast(void*)(GIB_SIZE * gibIndex); 

		// Create PML2 for this gib (sets present bits and allocates tables)
		ulong indexL4, indexL3, indexL2, indexL1;
		translateAddress(gibAddr, indexL1, indexL2, indexL3, indexL4);
		PageLevel3* pl3 = root.getOrCreateTable(indexL4, true);
		PageLevel2* pl2 = pl3.getOrCreateTable(indexL3, true);

		// This is to ensure canonical addressing (high memory vs low)
		if (cast(ulong)gibAddr >= 0x800000000000) {
			gibAddr = cast(void*)(cast(ulong)gibAddr | 0xffff000000000000);
		}

		// Return this gib address
		pagingLock.unlock();
		return gibAddr;
	}

	synchronized ErrorVal mapGib(void* gib, void* to) {
		pagingLock.lock();

		// Get the address of the gib, and find its PL3 and PL2
		ulong indexL4, indexL3, indexL2, indexL1;
		translateAddress(gib, indexL1, indexL2, indexL3, indexL4);
		PageLevel3* pl3 = root.getTable(indexL4);
		if (pl3 is null) {
			pagingLock.unlock();
			return ErrorVal.Fail;
		}

		ulong indexL4_to, indexL3_to, indexL2_to, indexL1_to;
		translateAddress(to, indexL1_to, indexL2_to, indexL3_to, indexL4_to);

		PageLevel3* pl3_to = root.getTable(indexL4_to);
		if (pl3_to is null) {
			pagingLock.unlock();
			return ErrorVal.Fail;
		}
		PageLevel2* pl2_to = pl3_to.getTable(indexL3_to);
		if (pl2_to is null) {
			pagingLock.unlock();
			return ErrorVal.Fail;
		}

		pl3.entries[indexL3].pml = pl3_to.entries[indexL3_to].pml;
		pl3.entries[indexL3].us = 1;

		pagingLock.unlock();
		return ErrorVal.Success;
	}

	// Return an address to a new gib (kernel)
	ulong nextGib = (256 * 512);
	const ulong MAX_GIB = (512 * 512);
	const ulong GIB_SIZE = (512 * 512 * PAGESIZE);

	ubyte* gibAddress(uint gibIndex) {
		// Find initial address of gib
		ubyte* gibAddr = cast(ubyte*)0x0;
		gibAddr += (GIB_SIZE * cast(ulong)gibIndex);

		// Make Canonical
		if (cast(ulong)gibAddr >= 0x800000000000UL) {
			gibAddr = cast(ubyte*)(cast(ulong)gibAddr | 0xffff000000000000UL);
		}

		return gibAddr;
	}

	bool createGib(ubyte* location, ulong size, uint flags) {
		// Find page translation
		ulong indexL4, indexL3, indexL2, indexL1;
		translateAddress(location, indexL1, indexL2, indexL3, indexL4);

		// Allocate paging structures
		bool usermode = (flags & Access.Kernel) == 0;
		PageLevel3* pl3 = root.getOrCreateTable(indexL4, usermode);
		PageLevel2* pl2 = pl3.getOrCreateTable(indexL3, usermode);

		return true;
	}

	ubyte* allocGib(ref ubyte* location, uint gibIndex, uint flags) {
		// Get initial address of gib
		ubyte* gibAddr = gibAddress(gibIndex);

		// Find page translation
		ulong indexL4, indexL3, indexL2, indexL1;
		translateAddress(gibAddr, indexL1, indexL2, indexL3, indexL4);

		// Allocate paging structures
		bool usermode = (flags & Access.Kernel) == 0;
		PageLevel3* pl3 = root.getOrCreateTable(indexL4, usermode);
		PageLevel2* pl2 = pl3.getOrCreateTable(indexL3, usermode);

		// Physical address of gib
		location = pl3.entries[indexL3].location;

		// pl2 is your gib structure.
		return gibAddr;
	}
	
	bool closeGib(ubyte* location) {
		// Find page translation
		ulong indexL4, indexL3, indexL2, indexL1;
		translateAddress(location, indexL1, indexL2, indexL3, indexL4);

		PageLevel3* pl3 = root.getTable(indexL4);
		if (pl3 is null) {
			return false;
		}

		pl3.setTable(indexL3, null, false);
		return true;
	}

	bool openGib(ubyte* location, uint flags) {
		// Find page translation
		ulong indexL4, indexL3, indexL2, indexL1;
		translateAddress(location, indexL1, indexL2, indexL3, indexL4);

		bool usermode = (flags & Access.Kernel) == 0;
		PageLevel3* pl3 = root.getOrCreateTable(indexL4, usermode);

		pl3.setTable(indexL3, location, usermode);

		return true;
	}

	ubyte* openGib(ubyte* location, uint gibIndex, uint flags) {
		ubyte* gibAddr = gibAddress(gibIndex);

		// Find page translation
		ulong indexL4, indexL3, indexL2, indexL1;
		translateAddress(gibAddr, indexL1, indexL2, indexL3, indexL4);

		bool usermode = (flags & Access.Kernel) == 0;
		PageLevel3* pl3 = root.getOrCreateTable(indexL4, usermode);

		pl3.setTable(indexL3, location, usermode);

		return gibAddr;
	}

	ErrorVal mapRegion(void* gib, void* physAddr, ulong regionLength) {
		mapRegion(null, physAddr, regionLength, gib, true);
		return ErrorVal.Success;
	}

	// Using heapAddress, this will add a region to the kernel space
	// It returns the virtual address to this region.
	synchronized void* mapRegion(void* physAddr, ulong regionLength) {
		// Sanitize inputs

		// physAddr should be floored to the page boundary
		// regionLength should be ceilinged to the page boundary
		pagingLock.lock();
		ulong curPhysAddr = cast(ulong)physAddr;
		regionLength += (curPhysAddr % PAGESIZE);
		curPhysAddr -= (curPhysAddr % PAGESIZE);

		// Set the new starting address
		physAddr = cast(void*)curPhysAddr;

		// Get the end address
		curPhysAddr += regionLength;

		// Align the end address
		if ((curPhysAddr % PAGESIZE) > 0)
		{
			curPhysAddr += PAGESIZE - (curPhysAddr % PAGESIZE);
		}

		// Define the end address
		void* endAddr = cast(void*)curPhysAddr;

		// This region will be located at the current heapAddress
		void* location = heapAddress;

		if (kernelMapped) {
			doHeapMap(physAddr, endAddr);
		}
		else {
			heapMap!(true)(physAddr, endAddr);
		}

		// Return the position of this region
		pagingLock.unlock();
		return location;
	}

	synchronized ulong mapRegion(PageLevel4* rootTable, void* physAddr, ulong regionLength, void* virtAddr = null, bool writeable = false) {
		if (virtAddr is null) {
			virtAddr = physAddr;
		}
		// Sanitize inputs

		pagingLock.lock();
		// physAddr should be floored to the page boundary
		// regionLength should be ceilinged to the page boundary
		ulong curPhysAddr = cast(ulong)physAddr;
		regionLength += (curPhysAddr % PAGESIZE);
		curPhysAddr -= (curPhysAddr % PAGESIZE);

		// Set the new starting address
		physAddr = cast(void*)curPhysAddr;

		// Get the end address
		curPhysAddr += regionLength;

		// Align the end address
		if ((curPhysAddr % PAGESIZE) > 0) {
			curPhysAddr += PAGESIZE - (curPhysAddr % PAGESIZE);
		}

		// Define the end address
		void* endAddr = cast(void*)curPhysAddr;

		heapMap!(false, false)(physAddr, endAddr, virtAddr, writeable);
		pagingLock.unlock();

		return regionLength;
	}

	PageLevel4* kernelPageTable() {
		return cast(PageLevel4*)0xfffffffffffff000;
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
	void* rootPhysical;


// -- Mapping Functions -- //

	template heapMap(bool initialMapping = false, bool kernelLevel = true) {
		void heapMap(void* physAddr, void* endAddr, void* virtAddr = heapAddress, bool writeable = true) {

			// Do the mapping
			PageLevel3* pl3;
			PageLevel2* pl2;
			PageLevel1* pl1;
			ulong indexL1, indexL2, indexL3, indexL4;

			void* startAddr = physAddr;

			// Find the initial page
			translateAddress(virtAddr, indexL1, indexL2, indexL3, indexL4);

			// From there, map the region
			ulong done = 0;
			for ( ; indexL4 < 512 && physAddr < endAddr ; indexL4++ )
			{
				// get the L3 table
				static if (initialMapping) {
					if (root.entries[indexL4].present) {
						pl3 = cast(PageLevel3*)(root.entries[indexL4].address << 12);
					}
					else {
						pl3 = cast(PageLevel3*)PageAllocator.allocPage();
						*pl3 = PageLevel3.init;
						root.entries[indexL4].pml = cast(ulong)pl3;
						root.entries[indexL4].present = 1;
						root.entries[indexL4].rw = 1;
						static if (!kernelLevel) {
							root.entries[indexL4].us = 1;
						}
					}
				}
				else {
					pl3 = root.getOrCreateTable(indexL4, !kernelLevel);
					//static if (!kernelLevel) { kprintfln!("pl3 {}")(indexL4); }
				}

				for ( ; indexL3 < 512 ; indexL3++ )
				{
					// get the L2 table
					static if (initialMapping) {
						if (pl3.entries[indexL3].present) {
							pl2 = cast(PageLevel2*)(pl3.entries[indexL3].address << 12);
						}
						else {
							pl2 = cast(PageLevel2*)PageAllocator.allocPage();
							*pl2 = PageLevel2.init;
							pl3.entries[indexL3].pml = cast(ulong)pl2;
							pl3.entries[indexL3].present = 1;
							pl3.entries[indexL3].rw = 1;
							static if (!kernelLevel) {
								pl3.entries[indexL3].us = 1;
							}
						}
					}
					else {
						pl2 = pl3.getOrCreateTable(indexL3, !kernelLevel);
//						static if (!kernelLevel) { kprintfln!("pl2 {}")(indexL3); }
					}

					for ( ; indexL2 < 512 ; indexL2++ )
					{
						// get the L1 table
						static if (initialMapping) {
							if (pl2.entries[indexL2].present) {
								pl1 = cast(PageLevel1*)(pl2.entries[indexL2].address << 12);
							}
							else {
								pl1 = cast(PageLevel1*)PageAllocator.allocPage();
								*pl1 = PageLevel1.init;
								pl2.entries[indexL2].pml = cast(ulong)pl1;
								pl2.entries[indexL2].present = 1;
								pl2.entries[indexL2].rw = 1;
								static if (!kernelLevel) {
									pl2.entries[indexL2].us = 1;
								}
							}
						}
						else {
							//static if (!kernelLevel) { kprintfln!("attempting pl1 {}")(indexL2); }
							pl1 = pl2.getOrCreateTable(indexL2, !kernelLevel);
							//static if (!kernelLevel) { kprintfln!("pl1 {}")(indexL2); }
						}

						for ( ; indexL1 < 512 ; indexL1++ )
						{
							// set the address
							if (pl1.entries[indexL1].present) {
								// Page already allocated
								// XXX: Fail
							}

							pl1.entries[indexL1].pml = cast(ulong)physAddr;

							pl1.entries[indexL1].present = 1;
							pl1.entries[indexL1].rw = writeable;
							pl1.entries[indexL1].pat = 1;
							static if (!kernelLevel) {
								pl1.entries[indexL1].us = 1;
							}

							physAddr += PAGESIZE;
							done += PAGESIZE;

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
			ulong regionLength = cast(ulong)endAddr - cast(ulong)startAddr;

			// Relocate heap address
			static if (kernelLevel) {
				heapAddress += regionLength;
			}
		}
	}

	alias heapMap!(false) doHeapMap;

}

// -- Structures -- //

	// The x86 implements a four level page table.
	// We use the 4KB page size hierarchy

	// The levels are defined here, many are the same but they need
	// to be able to be typed differently so we don't make a stupid
	// mistake.

	struct SecondaryField {

		ulong pml;

		mixin(Bitfield!(pml,
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

		ubyte* location() {
			return cast(ubyte*)(cast(ulong)address() << 12);
		}
	}
	
	struct PrimaryField {

		ulong pml;

		mixin(Bitfield!(pml,
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

		ubyte* location() {
			return cast(ubyte*)(cast(ulong)address() << 12);
		}
	}

	struct PageLevel4 {
		SecondaryField[512] entries;

		PageLevel3* getTable(uint idx) {
			if (entries[idx].present == 0) {
				return null;
			}
			
			// Calculate virtual address
			return cast(PageLevel3*)(0xFFFFFF7F_BFE00000 + (idx << 12));
		}

		void setTable(uint idx, ubyte* address, bool usermode = false) {
			entries[idx].pml = cast(ulong)address;
			entries[idx].present = 1;
			entries[idx].rw = 1;
			entries[idx].us = usermode;
		}

		PageLevel3* getOrCreateTable(uint idx, bool usermode = false) {
			PageLevel3* ret = getTable(idx);

			if (ret is null) {
				// Create Table
				ret = cast(PageLevel3*)PageAllocator.allocPage();

				// Set table entry
				entries[idx].pml = cast(ulong)ret;
				entries[idx].present = 1;
				entries[idx].rw = 1;
				entries[idx].us = usermode;

				// Calculate virtual address
				ret = cast(PageLevel3*)(0xFFFFFF7F_BFE00000 + (idx << 12));

				*ret = PageLevel3.init;
			}

			return ret;
		}
	}

	struct PageLevel3 {
		SecondaryField[512] entries;

		PageLevel2* getTable(uint idx) {
			if (entries[idx].present == 0) {
				return null;
			}

			ulong baseAddr = cast(ulong)this;
			baseAddr &= 0x1FF000;
			baseAddr >>= 3;
			return cast(PageLevel2*)(0xFFFFFF7F_C0000000 + ((baseAddr + idx) << 12));
		}

		void setTable(uint idx, ubyte* address, bool usermode = false) {
			entries[idx].pml = cast(ulong)address;
			entries[idx].present = 1;
			entries[idx].rw = 1;
			entries[idx].us = usermode;
		}

		PageLevel2* getOrCreateTable(uint idx, bool usermode = false) {
			PageLevel2* ret = getTable(idx);

			if (ret is null) {
				// Create Table
				ret = cast(PageLevel2*)PageAllocator.allocPage();

				// Set table entry
				entries[idx].pml = cast(ulong)ret;
				entries[idx].present = 1;
				entries[idx].rw = 1;
				entries[idx].us = usermode;

				// Calculate virtual address
				ulong baseAddr = cast(ulong)this;
				baseAddr &= 0x1FF000;
				baseAddr >>= 3;
				ret = cast(PageLevel2*)(0xFFFFFF7F_C0000000 + ((baseAddr + idx) << 12));

				*ret = PageLevel2.init;
				//if (usermode) { kprintfln!("creating pl3 {}")(idx); }
			}

			return ret;
		}
	}
	
	struct PageLevel2 {
		SecondaryField[512] entries;

		PageLevel1* getTable(uint idx) {
//			kprintfln!("getting pl2 {}?")(idx);
			if (entries[idx].present == 0) {
//				kprintfln!("no pl2 {}!")(idx);
				return null;
			}
//			kprintfln!("getting pl2 {}!")(idx);

			ulong baseAddr = cast(ulong)this;
			baseAddr &= 0x3FFFF000;
			baseAddr >>= 3;
			return cast(PageLevel1*)(0xFFFFFF80_00000000 + ((baseAddr + idx) << 12));
		}

		void setTable(uint idx, ubyte* address, bool usermode = false) {
			entries[idx].pml = cast(ulong)address;
			entries[idx].present = 1;
			entries[idx].rw = 1;
			entries[idx].us = usermode;
		}

		PageLevel1* getOrCreateTable(uint idx, bool usermode = false) {
			PageLevel1* ret = getTable(idx);
			
			if (ret is null) {
				// Create Table
//				if (usermode) { kprintfln!("creating pl2 {}?")(idx); }
				ret = cast(PageLevel1*)PageAllocator.allocPage();

				// Set table entry
				entries[idx].pml = cast(ulong)ret;
				entries[idx].present = 1;
				entries[idx].rw = 1;
				entries[idx].us = usermode;

				// Calculate virtual address
				ulong baseAddr = cast(ulong)this;
				baseAddr &= 0x3FFFF000;
				baseAddr >>= 3;
				ret = cast(PageLevel1*)(0xFFFFFF80_00000000 + ((baseAddr + idx) << 12));

				*ret = PageLevel1.init;
//				if (usermode) { kprintfln!("creating pl2 {}")(idx); }
			}

			return ret;
		}
	}

	struct PageLevel1 {
		PrimaryField[512] entries;

		void* physicalAddress(uint idx) {
			return cast(void*)(entries[idx].address << 12);
		}
	}

