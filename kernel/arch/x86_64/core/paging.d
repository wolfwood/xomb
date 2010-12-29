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

// Import some arch-dependent modules
import kernel.arch.x86_64.linker;	// want linker info

import kernel.arch.x86_64.core.idt;

// Import information about the system
// (we need to know where the kernel is)
import kernel.system.info;

// We need to restart the console driver
import kernel.dev.console;

import architecture.mutex;

import user.environment;

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
		PageLevel3* globalRoot = cast(PageLevel3*)PageAllocator.allocPage();

		//kprintfln!("root: {} pl3: {} pl2: {}")(root, pl3, pl2);

		// Initialize the structure. (Zero it)
		*root = PageLevel4.init;
		*globalRoot = PageLevel3.init;
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

		// Map entry 509 to the global root
		root.entries[509].pml = cast(ulong)globalRoot;
		root.entries[509].present = 1;
		root.entries[509].rw = 1;

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

		ulong indexL4, indexL3, indexL2, indexL1;
		translateAddress(addr, indexL1, indexL2, indexL3, indexL4);

		// check for gib status
		PageLevel3* pl3 = root.getTable(indexL4);
		if (pl3 is null) {
			// NOT AVAILABLE

				if (stack.rip < 0xf_0000_0000_0000) {
					kprintfln!("User Mode Page Fault {x}")(stack.rip);
				}

				kprintfln!("Non-Gib access.  looping 4eva. CR2 = {}")(addr);

				for(;;){}
		}
		else {
			PageLevel2* pl2 = pl3.getTable(indexL3);
			if (pl2 is null) {
				// NOT AVAILABLE (FOR SOME REASON)

				if (stack.rip < 0xf_0000_0000_0000) {
					kprintfln!("User Mode Page Fault {x}")(stack.rip);
				}

				kprintfln!("Non-Gib access.  looping 4eva. CR2 = {}")(addr);

				for(;;){}
			}
			else {

				// Allocate Page 
				// XXX: only if gib is allocate on access!!
				addr = cast(void*)(cast(ulong)addr & 0xffff_ffff_ffff_f000UL);

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

	AddressSpace createAddressSpace() {
		// XXX: the place where the address foo is stored is hard coded in context :(
		// and now it is going to be hardcoded here :(

		// Make a new root pagetable
		ubyte* newRootPhysAddr = cast(ubyte*)PageAllocator.allocPage();

		PageLevel3* addressRoot = root.getOrCreateTable(255);

		PageLevel2* addressSpace;


		uint idx = 0;
		for(uint i = 1; i < 512; i++) {
			if (addressRoot.getTable(i) is null) {
				addressRoot.setTable(i, newRootPhysAddr, false);
				addressSpace = addressRoot.getTable(i);
				idx = i;
				break;
			}
		}

		if(idx == 0){
			return null;
		}


		// Initialize the address space root page table
		*(cast(PageLevel4*)addressSpace) = PageLevel4.init;

		// Map in kernel pages
		addressSpace.entries[256].pml = root.entries[256].pml;
		addressSpace.entries[509].pml = root.entries[509].pml;

		addressSpace.entries[511].pml = cast(ulong)newRootPhysAddr;
		addressSpace.entries[511].present = 1;
		addressSpace.entries[511].rw = 1;


		// Create Level 3 and Level 2 for page trick
		void* pl3addr = PageAllocator.allocPage();
		void* pl2addr = PageAllocator.allocPage();

		addressSpace.entries[510].pml = cast(ulong)pl3addr;
		addressSpace.entries[510].present = 1;
		addressSpace.entries[510].rw = 1;

		PageLevel1* fakePl3 = addressSpace.getTable(510);
		*(cast(PageLevel3*)fakePl3) = PageLevel3.init;


		// Map entry 510 to the next level
		fakePl3.entries[510].pml = cast(ulong)pl2addr;
		fakePl3.entries[510].present = 1;
		fakePl3.entries[510].rw = 1;

		PageLevel2* fakePl2 = cast(PageLevel2*)createAddress(510, 510, idx, 255);//fakePl3.getTable(510);
		*fakePl2 = PageLevel2.init;

		// Map entries 511 to the PML4
		fakePl3.entries[511].pml = cast(ulong)newRootPhysAddr;
		fakePl3.entries[511].present = 1;
		fakePl3.entries[511].rw = 1;

		fakePl2.entries[511].pml = cast(ulong)newRootPhysAddr;
		fakePl2.entries[511].present = 1;
		fakePl2.entries[511].rw = 1;

		// insert parent into child
		fakePl3 = addressSpace.getOrCreateTable(255);
		fakePl3.entries[0].pml = root.entries[511].pml;
		fakePl3.entries[0].present = 1;
		// child should not be able to edit parent's root table
		fakePl3.entries[0].rw = 0;

		return cast(AddressSpace)addressSpace;
	}

	synchronized ErrorVal switchAddressSpace(AddressSpace as){

		if(as is null){
			// XXX - just decode phys addr directly?
			as = cast(AddressSpace)root.getTable(255).getTable(0);
		}

		// XXX: error checking

		ulong indexL4, indexL3, indexL2, indexL1;
				
		translateAddress(cast(ubyte*)as, indexL1, indexL2, indexL3, indexL4);

		PageLevel3* pl3 = root.getTable(indexL4);
		PageLevel2* pl2 = pl3.getTable(indexL3);
		PageLevel1* pl1 = pl2.getTable(indexL2);

		ulong newPhysRoot = cast(ulong)pl1.entries[indexL1].location();

		asm{
			mov RAX, newPhysRoot;
			mov CR3, RAX;
		}
		

		return ErrorVal.Success;
	}

	synchronized ErrorVal mapGib(AddressSpace destinationRoot, ubyte* location, ubyte* destination, AccessMode flags) {
		PageLevel4* addressSpace;

		// XXX: use switchAddressSpace() ?

		// XXX: look for special bit or something, or that the pointer is
		// within the AddressSpace area...
		if(destinationRoot is null){
			addressSpace = root;
			destinationRoot = cast(AddressSpace)addressSpace;
		}else{
			addressSpace = cast(PageLevel4*)destinationRoot;
		}

		// So. destinationRoot is the virtual address of the destination
		// root page table within the source (current) page table.
		// Due to paging trick magic.
		
		ulong indexL4, indexL3, indexL2, indexL1;
				
		translateAddress(cast(ubyte*)destinationRoot, indexL1, indexL2, indexL3, indexL4);

		PageLevel3* pl3 = root.getTable(indexL4);
		PageLevel2* pl2 = pl3.getTable(indexL3);
		PageLevel1* pl1 = pl2.getTable(indexL2);
		ulong addr = cast(ulong)pl1.entries[indexL1].location();

		ulong oldRoot = cast(ulong)root.entries[511].location();
		
		// Now, figure out the physical address of the gib root.

		translateAddress(location, indexL1, indexL2, indexL3, indexL4);
		pl3 = root.getTable(indexL4);
		ubyte* locationAddr = cast(ubyte*)pl3.entries[indexL3].location();

		// Goto the other address space
		asm {
			mov RAX, addr;
			mov CR3, RAX;
		}

		// Add an entry into the new address space that shares the gib of the old
		translateAddress(destination, indexL1, indexL2, indexL3, indexL4);
		pl3 = root.getOrCreateTable(indexL4, true);
		pl3.setTable(indexL3, locationAddr, true);

		// Return to our old address space
		asm {
			mov RAX, oldRoot;
			mov CR3, RAX;
		}

		return ErrorVal.Success;
	}


	bool createGib(ubyte* location, ulong size, AccessMode flags) {
		// Find page translation
		ulong indexL4, indexL3, indexL2, indexL1;
		translateAddress(location, indexL1, indexL2, indexL3, indexL4);

		bool usermode = (flags & AccessMode.Kernel) == 0;

		if (flags & AccessMode.Global) {
			//XXX:  instead, getTable and isure this is created elsewhere for kernel/init
			PageLevel3* globalRoot = root.getOrCreateTable(509);

			PageLevel2* global_pl3 = globalRoot.getOrCreateTable(indexL4, usermode);
			PageLevel1* global_pl2 = global_pl3.getOrCreateTable(indexL3, usermode);

			// Now, global_pl2 is the global root of the gib!!!

			// Allocate paging structures
			PageLevel3* pl3 = root.getOrCreateTable(indexL4, usermode);
			pl3.setTable(indexL3, cast(ubyte*)global_pl3.entries[indexL3].location(), usermode);
		}
		else {
			PageLevel3* pl3 = root.getOrCreateTable(indexL4, usermode);
			PageLevel2* pl2 = pl3.getOrCreateTable(indexL3, usermode);
		}

		// XXX: Check for errors, maybe handle flags?!
		// XXX: return false if it is already there
		return true;
	}
	
	// XXX support multiple sizes
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


	// OLD
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

	bool openGib(ubyte* location, uint flags) {
		// Find page translation
		ulong indexL4, indexL3, indexL2, indexL1;
		translateAddress(location, indexL1, indexL2, indexL3, indexL4);

		bool usermode = (flags & AccessMode.Kernel) == 0;
		PageLevel3* pl3 = root.getOrCreateTable(indexL4, usermode);

		pl3.setTable(indexL3, location, usermode);

		return true;
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
