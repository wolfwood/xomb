// This module contains linker definitions

module kernel.globals;

import kernel.mem.vmem;

struct Globals
{
	static:

	// trampoline region in memory
	ubyte* trampolineStart;
	ubyte* trampolineEnd;
	
	// kernel region in memory
	ubyte* kernelStart;
	ubyte* kernelEnd;

	// kernel VM base
	ubyte* kernelVMemBase;

	void init()
	{
		// get trampoline start and end from linker
		asm
		{
			"movq $_trampoline, %0" :: "o" trampolineStart;
			"movq $_etrampoline, %0" :: "o" trampolineEnd;
		}

		trampolineStart += vMem.VM_BASE_ADDR;
		trampolineEnd += vMem.VM_BASE_ADDR;



		// get kernel start and end from linker
		asm
		{
			"movq $_kernel, %0" :: "o" kernelStart;
			"movq $_ekernel, %0" :: "o" kernelEnd;
		}

		kernelStart += vMem.VM_BASE_ADDR;
		kernelEnd += vMem.VM_BASE_ADDR;



		// get kernel base
		asm
		{
			"movq $_kernelBase, %0" :: "o" kernelVMemBase;
		}
	}
}
