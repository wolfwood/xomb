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

// for reporting userspacepage fault errors to parent
import architecture.cpu;

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

		//kprintfln!("About to map kernel")();
		mapRegion(System.kernel.start, System.kernel.length);

		void* bitmapLocation = heapAddress;

		// The first gib for the kernel
		nextGib++;

		// Assign the page fault handler
		IDT.assignHandler(&pageFaultHandler, 14);

		IDT.assignHandler(&generalProtectionFaultHandler, 13);

		// We now have the kernel mapped
		kernelMapped = true;

		// Save the physical address for later
		rootPhysical = cast(PhysicalAddress)root;

		// This is the virtual address for the page table
		root = cast(PageLevel4*)0xFFFFFF7F_BFDFE000;

		// All is well.
		return ErrorVal.Success;
	}

	void generalProtectionFaultHandler(InterruptStack* stack) {
		bool recoverable;

		if (stack.rip < 0xf_0000_0000_0000) {
			kprintf!("User Mode ")();
			recoverable = true;
		}else{
			kprintf!("Kernel Mode ")();
		}


		kprintfln!("General Protection Fault: instruction address {x}")(stack.rip);

		stack.dump();
		printStackTrace(cast(StackFrame*)stack.rbp);


		if(recoverable){
			PhysicalAddress deadChild;

			switchAddressSpace(null, deadChild);

			Cpu.enterUserspace(3, deadChild);
		}else{
			for(;;){}
		}
		// >>> Never reached <<<
	}

	void pageFaultHandler(InterruptStack* stack) {
		ulong cr2;

		asm {
			mov RAX, CR2;
			mov cr2, RAX;
		}

		// page not present or privilege violation?
		if((stack.errorCode & 1) == 0){
			bool allocate;
			walk!(pageFaultHelper)(root, cr2, allocate);

			if(allocate){
				return;
			}else{
				kprintf!("found incomplete page mapping without Alloc-On-Access permission on a ")();
			}
		}

		// --- an error has occured ---
		bool recoverable;

		if(stack.errorCode & 8){
			kprintf!("Reserved bit ")();
		}else{
			if(stack.errorCode & 4){
				kprintf!("User Mode ")();
				recoverable = true;
			}else{
				kprintf!("Kernel Mode ")();
			}
			if(stack.errorCode & 16){
				kprintf!("Instruction Fetch ")();
			}else{
				if(stack.errorCode & 2){
					kprintf!("Write ")();
				}else{
					kprintf!("Read ")();
				}
			}
		}

		kprintfln!("Fault at instruction {x} to address {x}")(stack.rip, cast(ubyte*)cr2);

		stack.dump();
		printStackTrace(cast(StackFrame*)stack.rbp);

		if(recoverable){
			PhysicalAddress deadChild;

			switchAddressSpace(null, deadChild);

			Cpu.enterUserspace(3, deadChild);
		}else{
			for(;;){}
		}
		// >>> Never reached <<<
	}

	template pageFaultHelper(T){
		bool pageFaultHelper(T table, uint idx, ref bool allocate){
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
					}else{
						auto intermediate = table.getOrCreateTable(idx, true);

						if(intermediate is null){
							allocate = false;
							return false;
						}
						return true;
					}
				}
				return false;
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

	Mutex pagingLock;

	AddressSpace createAddressSpace() {
		// Make a new root pagetable
		PhysicalAddress newRootPhysAddr = PageAllocator.allocPage();

		bool success;
		ulong idx, addrFrag;
		ubyte* vAddr;
		PageLevel!(3)* segmentParent;
		AccessMode flags = AccessMode.RootPageTable|AccessMode.Writable;

		// --- find a free slot to store the child's root, then map it in ---
		traverse!(preorderFindFreeSegmentHelper, noop)(root, cast(ulong)createAddress(0,0,1,255), cast(ulong)createAddress(0,0,255,255), vAddr, segmentParent);

		if(vAddr is null)
			return null;

		addrFrag = cast(ulong)vAddr;
		walk!(mapSegmentHelper)(root, addrFrag, flags, success, segmentParent, newRootPhysAddr);

		getNextIndex(addrFrag, idx);
		getNextIndex(addrFrag, idx);

		PageLevel2* addressSpace = root.getTable(255).getTable(idx);

		// --- initialize root ---
		*(cast(PageLevel4*)addressSpace) = PageLevel4.init;

		// Map in kernel pages
		addressSpace.entries[256].pml = root.entries[256].pml;
		addressSpace.entries[509].pml = root.entries[509].pml;

		addressSpace.entries[510].pml = cast(ulong)newRootPhysAddr;
		addressSpace.entries[510].setMode(AccessMode.User);

		// insert parent into child
		PageLevel1* fakePl3 = addressSpace.getOrCreateTable(255);

		if(fakePl3 is null)
			return null;

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

		// This region will be located at the current heapAddress
		void* location = heapAddress;

		ubyte* endAddr = cast(ubyte*)location + (curPhysAddr - cast(ulong)physAddr);
		PhysicalAddress pAddr = cast(PhysicalAddress)physAddr;

		bool failed;
		if (kernelMapped) {
			traverse!(preorderMapPhysicalAddressHelper, noop)(root, cast(ulong)location, cast(ulong)endAddr, pAddr, failed);
		}else{
			traverseInitialMapping!(preorderInitialMapPhysicalAddressHelper, noop)(root, cast(ulong)location, cast(ulong)endAddr, pAddr, failed);
		}

		heapAddress = endAddr;

		// Return the position of this region
		pagingLock.unlock();

		if(failed){
			return null;
		}else{
			return location + diff;
		}
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
		ubyte* endAddr = cast(ubyte*)virtAddr + (curPhysAddr - cast(ulong)physAddr);

		bool failed;
		PhysicalAddress pAddr = cast(PhysicalAddress)physAddr;
		traverse!(preorderMapPhysicalAddressHelper, noop)(root, cast(ulong)virtAddr, cast(ulong)endAddr, pAddr, failed);

		pagingLock.unlock();

		if(failed){
			return 0;
		}else{
			return regionLength;
		}
	}

	template preorderMapPhysicalAddressHelper(T){
		TraversalDirective preorderMapPhysicalAddressHelper(T table, uint idx, uint startIdx, uint endIdx, ref PhysicalAddress physAddr, ref bool failed){
			static if(T.level != 1){
				auto next = table.getOrCreateTable(idx, true);

				if(next is null){
					failed = true;
					return TraversalDirective.Stop;
				}

				return TraversalDirective.Descend;
			}else{
				table.entries[idx].pml = cast(ulong)physAddr;
				table.entries[idx].pat = 1;
				table.entries[idx].setMode(AccessMode.User|AccessMode.Writable|AccessMode.Executable);

				physAddr += PAGESIZE;

				return TraversalDirective.Skip;
			}
		}
	}

private:

// -- Flags -- //
	bool kernelMapped;


// -- Positions -- //
	void* heapAddress;


// -- Main Page Table -- //
	PageLevel4* root;
	PhysicalAddress rootPhysical;


	template preorderInitialMapPhysicalAddressHelper(T){
		TraversalDirective preorderInitialMapPhysicalAddressHelper(T table, uint idx, uint startIdx, uint endIdx, ref PhysicalAddress physAddr, ref bool failed){
			static if(T.level != 1){

				if(!table.entries[idx].present){
					auto next = PageAllocator.allocPage();

					if(next is null){
						failed = true;
						return TraversalDirective.Stop;
					}

					table.entries[idx].pml = cast(ulong)next;
					table.entries[idx].setMode(AccessMode.User|AccessMode.Writable|AccessMode.Executable);
					*cast(PageLevel!(T.level-1)*)table.entries[idx].location = (PageLevel!(T.level-1)).init;
				}
				return TraversalDirective.Descend;
			}else{
				table.entries[idx].pml = cast(ulong)physAddr;
				table.entries[idx].pat = 1;
				table.entries[idx].setMode(AccessMode.User|AccessMode.Writable|AccessMode.Executable);

				physAddr += PAGESIZE;

				return TraversalDirective.Skip;
			}
		}
	}


	template traverseInitialMapping(alias PRE, alias POST, T, S...){
		bool traverseInitialMapping(T table, ulong startAddr, ulong endAddr, ref S s){
			ulong startIdx, endIdx;

			getNextIndex(startAddr, startIdx);
			getNextIndex(endAddr, endIdx);

			for(uint i = startIdx; i <= endIdx; i++){
				ulong frontAddr, backAddr;

				if(i == startIdx){
					frontAddr = startAddr;
				}else{
					frontAddr = 0;
				}

				if(i == endIdx){
					backAddr = endAddr;
				}else{
					backAddr = ~0UL;
				}

				TraversalDirective directive = TraversalDirective.Descend;
				static if(!is(PRE == noop)){
					directive = PRE(table, i, startIdx, endIdx, s);
				}
				static if(T.level != 1){
					if(directive == TraversalDirective.Descend){
						auto childTable = cast(PageLevel!(T.level-1)*)table.entries[i].location();

						if(childTable !is null){
							bool stop = traverseInitialMapping!(PRE,POST)(childTable, frontAddr, backAddr, s);

							if(stop){
								return true;
							}
						}
					}else if(directive == TraversalDirective.Stop){
						return true;
					}
				}else{
					if(directive == TraversalDirective.Stop){
						return true;
					}
				}

				static if(!is(POST == noop)){
					POST(table, i, startIdx, endIdx, s);
				}
			}

			return false;
		}// end travesal()
	}
}
