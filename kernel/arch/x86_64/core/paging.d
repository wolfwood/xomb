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
	int count = 10;

	kprintfln!(" YOU LOOK SAD, SO I GOT YOU A STACK TRACE!")();

	while(count > 0 && isValidAddress(cast(ubyte*)start)){
		kprintfln!("return addr: {x} rbp: {x}")(start.returnAddr, start);
		start = start.next;
		count--;
	}
}

class Paging {
static:
	// --- Set Up ---
	ErrorVal initialize(){
		// Save the physical address for later
		rootPhysical = PageAllocator.allocPage();
		// Create a new page table.
		PageLevel!(4)* newRoot = cast(PageLevel!(4)*)rootPhysical;
		PageLevel!(3)* globalRoot = cast(PageLevel!(3)*)PageAllocator.allocPage();

		// Initialize the structure. (Zero it)
		*newRoot = (PageLevel!(4)).init;
		*globalRoot = (PageLevel!(3)).init;

		// Map entries 510 to the PML4
		newRoot.entries[510].pml = cast(ulong)rootPhysical;
		newRoot.entries[510].setMode(AccessMode.Read|AccessMode.User);

		/* currently the kernel isn't forced to respect the rw bit. if
			 this is enabled, another paging trick will be needed with
			 Writable permission for the kernel
		 */

		// Map entry 509 to the global root
		newRoot.entries[509].pml = cast(ulong)globalRoot;
		newRoot.entries[509].setMode(AccessMode.Read);

		// The current position of the kernel space. All gets appended to this address.
		heapAddress = cast(ubyte*)LinkerScript.kernelVMA + System.kernel.length;

		// map kernel into bootstrap root page table, so we can use paging trick
		ubyte* addr = createAddress(0, 0, 0, 257);//findFreeSegment(true, 512*oneGB).ptr;

		createGib!(PageLevel!(3))(addr, AccessMode.Writable|AccessMode.Executable);
		mapRegion(addr, System.kernel.start, System.kernel.length);

		// copy physical address to new root
		ulong idx, frag = cast(ulong)addr;
		getNextIndex(frag, idx);
		newRoot.entries[256].pml = root.entries[idx].pml;

		// Assign the page fault handler
		IDT.assignHandler(&pageFaultHandler, 14);
		IDT.assignHandler(&generalProtectionFaultHandler, 13);

		// All is well.
		return ErrorVal.Success;
	}

	ErrorVal install() {
		ulong rootAddr = cast(ulong)rootPhysical;
		asm {
			mov RAX, rootAddr;
			mov CR3, RAX;
		}

		/*
		if(heapAddress is null){

			// put mapRegion heap into its own segment
			heapAddress = findFreeSegment().ptr;

			assert(heapAddress !is null);

			bool success = createGib!(PageLevel!(3))(heapAddress, AccessMode.Writable);

			assert(success);
		}
		*/

		return ErrorVal.Success;
	}


	// --- Handlers ---
	void generalProtectionFaultHandler(InterruptStack* stack) {
		bool recoverable;

		if (stack.rip < 0xf_0000_0000_0000) {
			kprintf!("User Mode ")();
			recoverable = true;
		}
		else {
			kprintf!("Kernel Mode ")();
		}

		kprintfln!("General Protection Fault: instruction address {x}")(stack.rip);

		stack.dump();
		printStackTrace(cast(StackFrame*)stack.rbp);

		if(recoverable) {
			PhysicalAddress deadChild;

			switchAddressSpace(null, deadChild);
			Cpu.enterUserspace(3, deadChild);
		}
		else {
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
			root.walk!(pageFaultHelper)(cr2, allocate);

			if(allocate){
				return;
			}else{
				kprintf!("found incomplete page mapping without Alloc-On-Access permission on a ")();
			}
		}

		// --- an error has occured ---
		bool recoverable;

		if(stack.errorCode & 8){
			kprintfln!("You look angry that I wrote some bits in a reserved field.  Have some PTEs.")();
			uint depth = 4;
			root.walk!(pageEntryPrinter)(cr2, depth);

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

	bool pageEntryPrinter(T)(T table, uint idx, ref uint depth){
		if(table.entries[idx].present){
			kprintfln!("Level {}: {x}")(depth--, table.entries[idx].pml);

			return true;
		}

		return false;
	}


	// --- AddressSpace Manipulation ---
	AddressSpace createAddressSpace() {
		// Make a new root pagetable
		PhysicalAddress newRootPhysAddr = PageAllocator.allocPage();

		bool success;
		ulong idx, addrFrag;
		ubyte* vAddr;
		PageLevel!(3)* segmentParent;
		AccessMode flags = AccessMode.RootPageTable|AccessMode.Writable;

		// --- find a free slot to store the child's root, then map it in ---
		root.traverse!(preorderFindFreeSegmentHelper, noop)(cast(ulong)createAddress(0,0,1,255), cast(ulong)createAddress(0,0,255,255), vAddr, segmentParent);

		if(vAddr is null)
			return null;

		addrFrag = cast(ulong)vAddr;
		root.walk!(mapSegmentHelper)(addrFrag, flags, success, segmentParent, newRootPhysAddr);

		root.walk!(zeroPageTableHelper)(addrFrag, segmentParent);

		getNextIndex(addrFrag, idx);
		getNextIndex(addrFrag, idx);

		PageLevel!(2)* addressSpace = root.getTable(255).getTable(idx);

		// --- initialize root ---
		*(cast(PageLevel!(4)*)addressSpace) = (PageLevel!(4)).init;

		// Map in kernel pages
		addressSpace.entries[256].pml = root.entries[256].pml;
		addressSpace.entries[509].pml = root.entries[509].pml;

		addressSpace.entries[510].pml = cast(ulong)newRootPhysAddr;
		addressSpace.entries[510].setMode(AccessMode.User);

		// insert parent into child
		PageLevel!(1)* fakePl3 = addressSpace.getOrCreateTable(255);

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

		PhysicalAddress newRoot = findPhysicalAddressOfAddressSpace(as);

		if(newRoot is null)
			return ErrorVal.Fail;

		oldRoot = switchAddressSpace(newRoot);

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


	// --- Segment Manipulation ---

	// dropped synchronized because of an ldc bug w/ templates
	ErrorVal mapGib(T)(AddressSpace destinationRoot, ubyte* location, ubyte* destination, AccessMode flags) {
		bool success;

		if(flags & AccessMode.Global){
			PageLevel!(T.level -1)* globalSegmentParent;

			PhysicalAddress locationAddr = getPhysicalAddressOfSegment!(typeof(globalSegmentParent))(cast(ubyte*)getGlobalAddress(cast(AddressFragment)location));

			if(locationAddr is null)
				return ErrorVal.Fail;

			if(destination is null){ // our open, segment mapped from global space to destination address
				T* segmentParent;
				root.walk!(mapSegmentHelper)(cast(ulong)location, flags, success, segmentParent, locationAddr);
			}else{
				root.walk!(mapSegmentHelper)(getGlobalAddress(cast(ulong)destination), flags, success, globalSegmentParent, locationAddr);
			}
		}else{
			// verify destinationRoot is a valid root page table (or null for a local operation)
			if((destinationRoot !is null) && ((modesForAddress(destinationRoot) & AccessMode.RootPageTable) == 0)){
				return ErrorVal.Fail;
			}

			T* segmentParent;
			PhysicalAddress locationAddr = getPhysicalAddressOfSegment!(typeof(segmentParent))(location), oldRoot;

			if(locationAddr is null)
				return ErrorVal.Fail;

			if(destinationRoot !is null){
				// Goto the other address space
				switchAddressSpace(destinationRoot, oldRoot);
			}

			root.walk!(mapSegmentHelper)(cast(ulong)destination, flags, success, segmentParent, locationAddr);

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

	// dropped synchronized because of an ldc bug w/ templates
	template createGib(T){
		bool createGib(ubyte* location, AccessMode flags){
			bool global = (flags & AccessMode.Global) != 0, success;

			ulong vAddr = cast(ulong)location;
			PhysicalAddress phys = PageAllocator.allocPage();

			if(phys is null)
				return false;

			T* segmentParent;
			root.walk!(mapSegmentHelper)(vAddr, flags, success, segmentParent, phys);

			root.walk!(zeroPageTableHelper)(vAddr, segmentParent);

			static if(T.level != 1){
				// 'map' the segment into the Global Space
				if(success && global){
					PageLevel!(T.level -1)* globalSegmentParent;
					success = false;

					root.walk!(mapSegmentHelper)(getGlobalAddress(vAddr), flags, success, globalSegmentParent, phys);
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

	bool zeroPageTableHelper(U, T)(T table, uint idx, ref U segmentParent){
		static if(is(T == U)){
			static if(U.level > 1){
				auto zeroTarget = table.getTable(idx);

				if(zeroTarget !is null)
					*zeroTarget = typeof(*zeroTarget).init;
			}else{
				// only matters if we allow 4k segment
			}

			return false;
		}else{
				static if(T.level != 1){
					auto intermediate = table.getOrCreateTable(idx, true);

					if(intermediate is null)
						return false;
				}
				return true;
		}
	}

	// XXX support multiple sizes
	bool closeGib(ubyte* location) {
		return true;
	}


	// --- Making Specific Physical Addresses Available ---

	// Using heapAddress, this will add a region to the kernel space
	// It returns the virtual address to this region. Use sparingly
	ubyte[] mapRegion(PhysicalAddress physAddr, ulong regionLength) {

		heapLock.lock();

		// This region will be located at the current heapAddress
		ubyte* location = heapAddress;

		ubyte[] result = mapRegion(location, physAddr, regionLength);

		if(result !is null){
			heapAddress = result[$..$].ptr;
		}

		heapLock.unlock();

		return result;
	}

	synchronized ubyte[] mapRegion(ubyte* virtAddr, PhysicalAddress physAddr, ulong regionLength) {
		assert((cast(ulong)virtAddr % PAGESIZE) == 0);

		// physAddr should be floored to the page boundary
		// regionLength should be ceilinged to the page boundary
		ulong diff = cast(ulong)physAddr % PAGESIZE;
		regionLength += diff;
		physAddr = physAddr - diff;

		// Align the end address
		if ((regionLength % PAGESIZE) > 0) {
			regionLength += PAGESIZE - (regionLength % PAGESIZE);
		}

		// Define the end address
		ubyte* endAddr = virtAddr + regionLength;

		bool failed;
		PhysicalAddress pAddr = cast(PhysicalAddress)physAddr;
		root.traverse!(preorderMapPhysicalAddressHelper, noop)(cast(ulong)virtAddr, cast(ulong)endAddr, pAddr, failed);

		if(failed){
			return null;
		}else{
			return (virtAddr)[diff..regionLength];
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

	const auto PAGESIZE = 4096;

private:
	// XXX: should be an array, so we can check for overflow
	ubyte* heapAddress;
	Mutex heapLock;

	// This is the physical address for the page table
	PhysicalAddress rootPhysical;
}
