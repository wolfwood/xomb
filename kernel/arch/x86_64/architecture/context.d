/*
 * context.d
 *
 * This module represents the environment to the architecture.
 *
 */

module architecture.context;

import kernel.arch.x86_64.core.paging;

import kernel.system.segment;

import kernel.core.error;
import kernel.core.kprintf;

import kernel.filesystem.ramfs;

import kernel.mem.pageallocator;

import user.environment;

struct Context {
public:

	ErrorVal initialize() {
		// Make a new root pagetable
		rootPhysAddr = PageAllocator.allocPage();
		root = cast(PageLevel4*)(Paging.mapRegion(rootPhysAddr, 4096));
		*root = PageLevel4.init;
		// Map in kernel pages
		root.entries[256].pml = Paging.kernelPageTable.entries[256].pml;
		root.entries[509].pml = Paging.kernelPageTable.entries[509].pml;
		root.entries[510].pml = Paging.kernelPageTable.entries[510].pml;

		root.entries[511].pml = cast(ulong)rootPhysAddr;
		root.entries[511].present = 1;
		root.entries[511].rw = 1;

		// Create Level 3 and Level 2 for page trick
		void* pl3addr = PageAllocator.allocPage();
		PageLevel3* pl3 = cast(PageLevel3*)(Paging.mapRegion(pl3addr, 4096));
		*pl3 = PageLevel3.init;
		void* pl2addr = PageAllocator.allocPage();
		PageLevel2* pl2 = cast(PageLevel2*)(Paging.mapRegion(pl2addr, 4096));
		*pl2 = PageLevel2.init;

		// Map entries 511 to the PML4
		root.entries[511].pml = cast(ulong)rootPhysAddr;
		root.entries[511].present = 1;
		root.entries[511].rw = 1;
		pl3.entries[511].pml = cast(ulong)rootPhysAddr;
		pl3.entries[511].present = 1;
		pl3.entries[511].rw = 1;
		pl2.entries[511].pml = cast(ulong)rootPhysAddr;
		pl2.entries[511].present = 1;
		pl2.entries[511].rw = 1;

		// Map entry 510 to the next level
		root.entries[510].pml = cast(ulong)pl3addr;
		root.entries[510].present = 1;
		root.entries[510].rw = 1;
		pl3.entries[510].pml = cast(ulong)pl2addr;
		pl3.entries[510].present = 1;
		pl3.entries[510].rw = 1;

		ulong addr = cast(ulong)rootPhysAddr;
		asm {
			mov RAX, addr;
			mov CR3, RAX;
		}
		//kprintfln!("b")();

		// Allocate Stack
		stack = PageAllocator.allocPage();
		Paging.mapRegion(null, stack, 4096, cast(void*)0xf0000000, true);
		stack = cast(void*)0xf0000000;
		//kprintfln!("c")();

		// Allocate AddressSpace area
		Paging.createGib(cast(ubyte*)(255UL << ((9*3) + 12)), 1024*1024*1024, AccessMode.Writable | AccessMode.Kernel);

		resourceHeap = cast(void*)0xe0000000;

		contextStack = PageAllocator.allocPage();
		contextStack = cast(void*)Paging.mapRegion(contextStack, 4096);

		// The first gib is the code and heap
		nextGib++;

		return ErrorVal.Success;
	}

	ErrorVal uninitialize() {
		// Remove page table
		// XXX: TODO

		// Deallocate Stack
		// XXX: TODO

		// Reclaim Resources
		// XXX: TODO

		return ErrorVal.Success;
	}

	ErrorVal preamble(void* entry) {
		ulong* stackSpace = cast(ulong*)(contextStack + 4096);

		// Push Things to Stack

		// SS (USER_DS with RPL of 3)
		stackSpace--;
		*stackSpace = ((8 << 3) | 3);

		// RSP (user stack)
		stackSpace--;
		*stackSpace = (cast(ulong)stack) + 4096;

		// FLAGS
		stackSpace--;
		*stackSpace = ((1 << 9) | (3 << 12));

		// CS (USER_CS with RPL of 3)
		stackSpace--;
		*stackSpace = ((9 << 3) | 3);

		// RIP (entry)
		stackSpace--;
		*stackSpace = cast(ulong)entry;

		// ERROR CODE and VECTOR NUMBER
		stackSpace--;
		*stackSpace = 0;
		stackSpace--;
		*stackSpace = 0;

		contextStackPtr = stackSpace;

		return ErrorVal.Success;
	}

	//Gib allocGib() {
	//	return Paging.allocUserGib(nextGib);
	//	nextGib++;
	//}

	ErrorVal map(void* physAddr, ulong length) {
		Paging.mapRegion(null, physAddr, length, cast(void*)0x100000);

		return ErrorVal.Success;
	}

	void* mapRegion(void* physAddr, ulong length) {
		void* addr = resourceHeap;
		resourceHeap += Paging.mapRegion(null, physAddr, length, cast(void*)resourceHeap, true);
		return addr;
	}

	ErrorVal mapExisting(void* virtAddrDestination, void* virtAddrSource, ulong length) {
		void* addr;
	   
		addr = Paging.translateAddress(virtAddrSource);
		map(addr, 4096);
		virtAddrSource += 4096;
		virtAddrDestination += 4096;

		while (length > 4096) {
			addr = Paging.translateAddress(virtAddrSource);
			map(addr, 4096);
			virtAddrSource += 4096;
			virtAddrDestination += 4096;
			length -= 4096;
		}

		return ErrorVal.Success;
	}

	ErrorVal alloc(void* virtAddr, ulong length, bool writeable = true) {

//		kprintfln!("alloc start {} for {}B")(virtAddr, length);
		// check validity of virtAddr
		if (cast(ulong)virtAddr > 0x00000000fffff000UL) {
			return ErrorVal.Fail;
		}
	
		void* physAddr = PageAllocator.allocPage(virtAddr);
		if (physAddr is null) { return ErrorVal.Fail; }

//		kprintfln!("alloc {} for {}B")(virtAddr, length);
		Paging.mapRegion(null, physAddr, 4096, virtAddr, writeable);
		virtAddr += 4096;

		while (length > 4096) {
			physAddr = PageAllocator.allocPage(virtAddr);
			if (physAddr is null) { return ErrorVal.Fail; }
			Paging.mapRegion(null, physAddr, 4096, virtAddr, writeable);
			virtAddr += 4096;
			length -= 4096;
		}
//		kprintfln!("alloc done {} for {}B")(virtAddr, length);

		return ErrorVal.Success;
	}

	ErrorVal allocSegment(ref Segment s) {
		return alloc(s.virtAddress, s.length, s.writeable);
	}

	void* install() {
		// Install Page Table
		ulong addr = cast(ulong)rootPhysAddr;
		asm {
			mov RAX, addr;
			mov CR3, RAX;
		}

		return contextStackPtr;
	}

	// first program entry, mimicking traditional _start() -> main()
	void upcallFirstEntry() {
		install();
		asm {
			// Get return from install() and set as stack pointer
			mov RSP, RAX;

			// Context Restore
			add RSP, 16;

			// pass 0 as argument to _start as UVT discriminator
			mov RDI, 0;

			// Go to userspace
			iretq;
		}
	}

	// enter thread scheduler
	void  upcallReentry() {
		install();
		asm {
			// Get return from install() and set as stack pointer
			mov RSP, RAX;

			// Context Restore
			add RSP, 16;

			// pass 1 as argument to _start as UVT discriminator
			mov RDI, 1;

			// Go to userspace
			iretq;
		}
	}

protected:

	void* stack;
	void* heap;

	void* contextStack;
	void* contextStackPtr;

	void* resourceHeap;

	void* rootPhysAddr;
	PageLevel4* root;

	ulong nextGib;
}
