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

struct GibAllocator {
static:
public:

	Gib alloc(uint gibIndex, uint flags) {
		Gib ret;
		ubyte* gibAddr = VirtualMemory.allocGib(gibIndex, flags);
		ret._start = gibAddr;
		ret._curpos = gibAddr;
		kprintfln!("Gib address: {}")(gibAddr);
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
	const auto GIB_SIZE = 1024UL * 1024UL * 1024UL;
}
