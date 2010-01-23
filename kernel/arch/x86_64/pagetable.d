/*
 * pagetable.d
 *
 * This module implements the magic behind page tables for the architecture.
 *
 */

module kernel.arch.x86_64.pagetable;

import kernel.arch.x86_64.core.paging;

import kernel.core.error;
import kernel.core.kprintf;

import kernel.mem.pageallocator;

struct PageTable {
public:

	ErrorVal initialize() {
		// Make a new root pagetable
		rootPhysAddr = PageAllocator.allocPageNoMap();
		root = cast(PageLevel3*)(Paging.mapRegion(rootPhysAddr, 4096));
		*root = PageLevel3.init;

		kprintfln!("New Page Table: {x} {x}")(rootPhysAddr, root);

		// Map to kernel page table
		Paging.kernelPageTable.entries[0].pml = cast(ulong)rootPhysAddr;
		Paging.kernelPageTable.entries[0].present = 1;
		Paging.kernelPageTable.entries[0].rw = 1;
		Paging.kernelPageTable.entries[0].us = 1;

		// Allocate Stack
		stack = PageAllocator.allocPageNoMap();
		Paging.mapRegion(null, stack, 4096, cast(void*)0x80000000);
		stack = cast(void*)0x80000000;

		contextStack = PageAllocator.allocPageNoMap();
		contextStack = cast(void*)Paging.mapRegion(contextStack, 4096);

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
		kprintfln!("success...")();

		return ErrorVal.Success;
	}

	ErrorVal alloc(void* virtAddr, ulong length) {
		void* physAddr = PageAllocator.allocPageNoMap();
		Paging.mapRegion(null, physAddr, 4096, virtAddr);
		virtAddr += 4096;

		while (length > 4096) {
			physAddr = PageAllocator.allocPageNoMap();
			kprintfln!("mapping: {x} -> {x}")(physAddr, virtAddr);
			Paging.mapRegion(null, physAddr, 4096, virtAddr);
			virtAddr += 4096;
			length -= 4096;
		}

		return ErrorVal.Success;
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

	void* rootPhysAddr;
	PageLevel3* root;
}
