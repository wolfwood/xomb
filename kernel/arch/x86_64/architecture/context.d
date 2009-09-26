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

import kernel.mem.heap;

struct Context {
public:

	ErrorVal initialize() {
		// Make a new root pagetable
		rootPhysAddr = Heap.allocPageNoMap();
		root = cast(PageLevel3*)(Paging.mapRegion(rootPhysAddr, 4096));
		*root = PageLevel3.init;

		// Map to kernel page table
		Paging.kernelPageTable.entries[0].pml = cast(ulong)rootPhysAddr;
		Paging.kernelPageTable.entries[0].present = 1;
		Paging.kernelPageTable.entries[0].rw = 1;
		Paging.kernelPageTable.entries[0].us = 1;

		// Allocate Stack
		stack = Heap.allocPageNoMap();
		Paging.mapRegion(null, stack, 4096, cast(void*)0x80000000);
		stack = cast(void*)0x80000000;

		resourceHeap = cast(void*)0x80f00000;

		contextStack = Heap.allocPageNoMap();
		contextStack = cast(void*)Paging.mapRegion(contextStack, 4096);

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

	ErrorVal map(void* physAddr, ulong length) {
		Paging.mapRegion(null, physAddr, length, cast(void*)0x100000);

		return ErrorVal.Success;
	}

	void* mapRegion(void* physAddr, ulong length) {
		void* addr = resourceHeap;
		resourceHeap += Paging.mapRegion(null, physAddr, length, cast(void*)resourceHeap);
		return addr;
	}

	ErrorVal alloc(void* virtAddr, ulong length) {

		// check validity of virtAddr
		if (cast(ulong)virtAddr > 0x00000000fffff000UL) {
			return ErrorVal.Fail;
		}
	
		void* physAddr = Heap.allocPageNoMap();
		if (physAddr is null) { return ErrorVal.Fail; }

		Paging.mapRegion(null, physAddr, 4096, virtAddr);
		virtAddr += 4096;

		while (length > 4096) {
			physAddr = Heap.allocPageNoMap();
			if (physAddr is null) { return ErrorVal.Fail; }
			Paging.mapRegion(null, physAddr, 4096, virtAddr);
			virtAddr += 4096;
			length -= 4096;
		}

		return ErrorVal.Success;
	}

	ErrorVal allocSegment(ref Segment s) {
		return alloc(s.virtAddress, s.length);
	}

	void* install() {

		// Install Page Table
		Paging.kernelPageTable.entries[0].address = (cast(ulong)rootPhysAddr) >> 12;

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
	PageLevel3* root;
}
