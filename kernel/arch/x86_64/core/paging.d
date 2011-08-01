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

import architecture.mutex;

import user.environment;


align(1) struct StackFrame{
	StackFrame* next;
	ulong returnAddr;
}

void printStackTrace(StackFrame* start){
	kprintfln!(" YOU LOOK SAD, SO I GOT YOU A STACK TRACE!")();

	StackFrame* curr = start, limit = start;

	limit += Paging.PAGESIZE;
	limit = cast(StackFrame*) ( cast(ulong)limit & ~(Paging.PAGESIZE-1));

	int count = 10;

	//&& curr < limit
	while(cast(ulong)curr > Paging.PAGESIZE && count > 0 && isValidAddress(cast(ubyte*)curr)){
		kprintfln!("return addr: {x} rbp: {x}")(curr.returnAddr, curr);
		curr = curr.next;
		count--;
	}
}

alias PageLevel!(4) PageLevel4;
alias PageLevel!(3) PageLevel3;
alias PageLevel!(2) PageLevel2;
alias PageLevel!(1) PageLevel1;

class Paging {
static:

	// The page size we are using
	const auto PAGESIZE = 4096;

	// This function will initialize paging and install a core page table.
	ErrorVal initialize() {
		// Create a new page table.
		root = cast(PageLevel4*)PageAllocator.allocPage();
		PageLevel3* globalRoot = cast(PageLevel3*)PageAllocator.allocPage();

		//kprintfln!("root: {} pl3: {} pl2: {}")(root, pl3, pl2);

		// Initialize the structure. (Zero it)
		*root = PageLevel4.init;
		*globalRoot = PageLevel3.init;

		// Map entries 510 to the PML4
		root.entries[510].pml = cast(ulong)root;
		root.entries[510].setMode(AccessMode.Read|AccessMode.User);

		/* currently the kernel isn't forced to respect the rw bit. if
			 this is enabled, another paging trick will be needed with
			 Writable permission for the kernel
		 */

		// Map entry 509 to the global root
		root.entries[509].pml = cast(ulong)globalRoot;
		root.entries[509].setMode(AccessMode.Read);

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

		IDT.assignHandler(&gpfHandler, 13);

		// We now have the kernel mapped
		kernelMapped = true;

		// Save the physical address for later
		rootPhysical = cast(PhysicalAddress)root;

		// This is the virtual address for the page table
		root = cast(PageLevel4*)0xFFFFFF7F_BFDFE000;

		// All is well.
		return ErrorVal.Success;
	}

	void gpfHandler(InterruptStack* stack) {
		stack.dump();

		if (stack.rip < 0xf_0000_0000_0000) {
			kprintfln!("User Mode General Protection Fault: instruction address {x}")(stack.rip);
		}else{
			kprintfln!("Kernel Mode General Protection Fault: instruction address {x}")(stack.rip);
		}

		printStackTrace(cast(StackFrame*)stack.rbp);
		
		for(;;){}
	}

	void faultHandler(InterruptStack* stack) {
		ulong cr2;

		asm {
			mov RAX, CR2;
			mov cr2, RAX;
		}

		ubyte* vAddr = cast(ubyte*)cr2;

		if((stack.errorCode & 7) == 7){
			// XXX: 'kill' child and return to parent?
			stack.dump();
			kprintfln!("User Mode Write Fault at {x} on Read-only page {x}, Error Code {x}")(stack.rip, vAddr, stack.errorCode);
			printStackTrace(cast(StackFrame*)stack.rbp);
			for(;;){}
		}

		if(stack.errorCode == 3){
			kprintfln!("Kernel Mode Write Fault at {x} on Read-only page {x}, Error Code {x}")(stack.rip, vAddr, stack.errorCode);
			printStackTrace(cast(StackFrame*)stack.rbp);
			for(;;){}
		}

		bool allocate;
		walk!(pageFaultHelper)(root, cr2, allocate, vAddr);

		if(!allocate){
			if (stack.rip < 0xf_0000_0000_0000) {
				kprintf!("User Mode")();
			}else{
				kprintf!("Kernel Mode")();
			}
			kprintfln!(" Page Fault on a non-allocate on access page.  Rip: {x}, Error Code: {x}, CR2: {}")(stack.rip, stack.errorCode, vAddr);

			printStackTrace(cast(StackFrame*)stack.rbp);

			for(;;){}
		}
	}

	template pageFaultHelper(T){
		bool pageFaultHelper(T table, uint idx, ref bool allocate, ref ubyte* vAddr){
			const AccessMode allocatingSegment = AccessMode.AllocOnAccess | AccessMode.Segment;

			if(table.entries[idx].present){
				if((table.entries[idx].getMode() & allocatingSegment) == allocatingSegment){
					allocate = true;
				}
				
				return true;
			}else{
				if(allocate){
					static if(T.level == 1){
						ubyte* page = PageAllocator.allocPage();

						if(page is null){
							allocate = false;
						}else{
							table.entries[idx].pml = cast(ulong)page;
							table.entries[idx].pat = 1;
							table.entries[idx].setMode(AccessMode.User|AccessMode.Writable|AccessMode.Executable);
						}

						return false;
					}else{
						auto intermediate = table.getOrCreateTable(idx, true);

						if(intermediate is null){
							allocate = false;
							return false;
						}
						return true;
					}

					return false;
				}else{
					return false;
				}
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
		PhysicalAddress newRootPhysAddr = PageAllocator.allocPage();

		PageLevel3* addressRoot = root.getOrCreateTable(255);

		PageLevel2* addressSpace;


		uint idx = 0;
		for(uint i = 1; i < 512; i++) {
			if (addressRoot.getTable(i) is null) {
				addressRoot.setTable(i, newRootPhysAddr, false);
				addressRoot.entries[i].setMode(AccessMode.RootPageTable);
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

		addressSpace.entries[510].pml = cast(ulong)newRootPhysAddr;
		addressSpace.entries[510].setMode(AccessMode.User);


		// insert parent into child
		 PageLevel1* fakePl3 = addressSpace.getOrCreateTable(255);
		fakePl3.entries[0].pml = root.entries[510].pml;
		// child should not be able to edit parent's root table
		fakePl3.entries[0].setMode(AccessMode.RootPageTable);


		return cast(AddressSpace)addressSpace;
	}

	ErrorVal switchAddressSpace(AddressSpace as, out PhysicalAddress oldRoot){
		if(as is null){
			// XXX - just decode phys addr directly?
			as = cast(AddressSpace)root.getTable(255).getTable(0);
		}

		// error checking
		if((modesForAddress(as) & AccessMode.RootPageTable) == 0){
			return ErrorVal.Fail;
		}

		oldRoot = switchAddressSpace(getPhysicalAddressOfSegment(as));

		return ErrorVal.Success;
	}

private:
	PhysicalAddress switchAddressSpace(PhysicalAddress newRoot){
		PhysicalAddress oldRoot = root.entries[510].location();

		asm{
			mov RAX, newRoot;
			mov CR3, RAX;
		}

		return oldRoot;
	}
public:

	synchronized ErrorVal mapGib(AddressSpace destinationRoot, ubyte* location, ubyte* destination, AccessMode flags) {
		bool success;

		if(flags & AccessMode.Global){
			if(location is null){
				PhysicalAddress locationAddr = getPhysicalAddressOfSegment(cast(ubyte*)getGlobalAddress(cast(AddressFragment)destination));

				PageLevel!(3)* segmentParent;
				walk!(mapSegmentHelper)(root, cast(ulong)destination, flags, success, segmentParent, locationAddr);
			}else{
				PhysicalAddress locationAddr = getPhysicalAddressOfSegment(cast(ubyte*)getGlobalAddress(cast(AddressFragment)location));

				PageLevel!(2)* segmentParent;
				walk!(mapSegmentHelper)(root, getGlobalAddress(cast(ulong)destination), flags, success, segmentParent, locationAddr);
			}
		}else{
			// verify destinationRoot is a valid root page table (or null for a local operation)
			if((destinationRoot !is null) && ((modesForAddress(destinationRoot) & AccessMode.RootPageTable) == 0)){
				return ErrorVal.Fail;
			}

			PhysicalAddress locationAddr = getPhysicalAddressOfSegment(location), oldRoot;

			if(destinationRoot !is null){
				// Goto the other address space
				switchAddressSpace(destinationRoot, oldRoot);
			}

			PageLevel!(3)* segmentParent;
			walk!(mapSegmentHelper)(root, cast(ulong)destination, flags, success, segmentParent, locationAddr);

			if(destinationRoot !is null){
				// Return to our old address space
				switchAddressSpace(oldRoot);
			}
		}

		if(success){
			return ErrorVal.Success;
		}else{
			return ErrorVal.Fail;
		}
	}

	template createGib(T){
		bool createGib(ubyte* location, AccessMode flags){
			bool global = (flags & AccessMode.Global) != 0, success;

			ulong vAddr = cast(ulong)location;
			PhysicalAddress phys = PageAllocator.allocPage();

			T* segmentParent;
			walk!(mapSegmentHelper)(root, vAddr, flags, success, segmentParent, phys);

			static if(T.level != 1){
				// 'map' the segment into the Global Space
				if(success && global){
					PageLevel!(T.level -1)* globalSegmentParent;
					success = false;

					walk!(mapSegmentHelper)(root, getGlobalAddress(vAddr), flags, success, globalSegmentParent, phys);
				}
			}

			return success;
		}
	}

	template mapSegmentHelper(U, T){
		bool mapSegmentHelper(T table, uint idx, ref AccessMode flags, ref bool success, ref U segmentParent, ref PhysicalAddress phys){
			static if(is(T == U)){
				if(table.entries[idx].present)
					return false;

				table.entries[idx].pml = cast(ulong)phys;
				table.entries[idx].setMode(AccessMode.Segment | flags);

				success = true;
				return false;
			}else{
				static if(T.level != 1){
					auto intermediate = table.getOrCreateTable(idx, true);

					if(intermediate is null)
						return false;

				return true;
				}else{
					// will nevar happen
					return false;
				}
			}
		}
	}

	// XXX support multiple sizes
	bool closeGib(ubyte* location) {
		return true;
	}


	// OLD
	// Return an address to a new gib (kernel)
	ulong nextGib = (256 * 512);
	const ulong MAX_GIB = (512 * 512);
	const ulong GIB_SIZE = (512 * 512 * PAGESIZE);

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
		ulong diff = curPhysAddr % PAGESIZE;

		regionLength += diff;
		curPhysAddr -= diff;

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
		return location + diff;
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
	PhysicalAddress rootPhysical;


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
