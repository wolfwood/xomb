/*
 * giballocator.d
 *
 * This module manages gib allocation on the current page table.
 *
 */

module kernel.mem.giballocator;

import architecture.vm;

import kernel.mem.gib;

import kernel.core.error;
import kernel.core.kprintf;
import kernel.core.log;

enum Access : uint {
	Read = 1,
	Write = 2,
	Kernel = 128,
}

struct GibAllocator {
static:
public:

	Gib alloc(uint flags) {
		Gib ret;
		uint gibIndex = 0;
		if (flags & Access.Kernel != 0) {
			// kernel gib
			gibIndex = nextFreeKernelGib;
			nextFreeKernelGib++;
		}
		ubyte* gibAddr = VirtualMemory.allocGib(gibIndex, flags);
		ret._start = gibAddr;
		ret._curpos = gibAddr;
		kprintfln!("Gib (kernel) address: {} at {}")(gibAddr, gibIndex);
		return ret;
	}

	Gib open(uint gibIndex, uint flags) {
		Gib ret;
		return ret;
	}

	ErrorVal free(uint gibIndex) {	
		return ErrorVal.Success;
	}

private:
	const auto KERNEL_START = 1024UL * 128UL;
	const auto MAX_GIBS = 256UL * 1024UL;
	const auto GIB_SIZE = 1024UL * 1024UL * 1024UL;
	
	// Must take into account the first gib is always the kernel executable
	uint nextFreeKernelGib = KERNEL_START + 1;
	ulong[(MAX_GIBS+64)/64] gibBitmap;

}
