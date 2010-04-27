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
	Execute = 4,
	Kernel = 128,
}

struct GibAllocator {
static:
public:

	Gib alloc(uint flags, uint gibIndex = 1) {
		Gib ret;
		if (flags & Access.Kernel != 0) {
			// kernel gib
			gibIndex = nextFreeKernelGib;
			nextFreeKernelGib++;
		}
		ubyte* gibAddr = VirtualMemory.allocGib(ret._gibaddr, gibIndex, flags);
		ret._start = gibAddr + VirtualMemory.pagesize();
		ret._metadata = cast(Metadata*)(ret._start - Metadata.sizeof);
		ret.rewind();
		kprintfln!("Gib (kernel) address: {} at {} AT {}")(gibAddr, gibIndex, ret._gibaddr);
		return ret;
	}

	Gib open(ubyte* gibaddr, uint flags, uint gibIndex = 1) {
		Gib ret;
		ret._gibaddr = gibaddr;
		if (flags & Access.Kernel != 0) {
			// kernel gib
			gibIndex = nextFreeKernelGib;
			nextFreeKernelGib++;
		}
		ubyte* newAddr = VirtualMemory.openGib(gibaddr, gibIndex, flags);
		ret._start = newAddr + VirtualMemory.pagesize();
		ret._metadata = cast(Metadata*)(ret._start - Metadata.sizeof);
		ret.rewind();
		return ret;
	}

	ErrorVal free(ubyte* gibaddr) {	
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
