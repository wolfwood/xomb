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

import kernel.mem.heap;

struct Context {
public:

	ErrorVal initialize() {
		// Make a new root pagetable
		rootPhysAddr = Heap.allocPageNoMap();
		root = cast(PageLevel4*)(Paging.mapRegion(rootPhysAddr, 4096));
		*root = *Paging.kernelPageTable;
		root.entries[511].pml = cast(ulong)rootPhysAddr;
		root.entries[511].present = 1;
		root.entries[511].rw = 1;
		PageLevel3* pl3 = root.getTable(510);
		pl3.entries[511] = root.entries[511];
		PageLevel2* pl2 = pl3.getTable(510);
		pl2.entries[511] = root.entries[511];

		kprintfln!("a")();

		ulong addr = cast(ulong)rootPhysAddr;
		asm {
			mov RAX, addr;
			mov CR3, RAX;
		}
		kprintfln!("b")();

		// Allocate Stack
		stack = Heap.allocPageNoMap();
		Paging.mapRegion(null, stack, 4096, cast(void*)0xe00000, true);
		stack = cast(void*)0xe00000;
		kprintfln!("c")();

		resourceHeap = cast(void*)0xf00000;

		contextStack = Heap.allocPageNoMap();
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

	Gib allocGib() {
		return Paging.allocUserGib(nextGib);
		nextGib++;
	}

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

		// check validity of virtAddr
		if (cast(ulong)virtAddr > 0x00000000fffff000UL) {
			return ErrorVal.Fail;
		}
	
		void* physAddr = Heap.allocPageNoMap();
		if (physAddr is null) { return ErrorVal.Fail; }

		Paging.mapRegion(null, physAddr, 4096, virtAddr, writeable);
		virtAddr += 4096;

		while (length > 4096) {
			physAddr = Heap.allocPageNoMap();
			if (physAddr is null) { return ErrorVal.Fail; }
			Paging.mapRegion(null, physAddr, 4096, virtAddr, writeable);
			virtAddr += 4096;
			length -= 4096;
		}

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

	void execute() {
		install();
		asm {
			// Get return from install() and set as stack pointer
			mov RSP, RAX;

			// Context Restore

			add RSP, 16;

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
