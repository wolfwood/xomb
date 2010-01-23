/*
 * linker.d
 *
 * This module coordinates with the linker script to pull
 * symbols defined in the script to the kernel world.
 *
 */

module kernel.arch.x86_64.linker;

extern(C)
{
	// The end of the entire kernel
	extern ubyte _ekernel;

	// The physical address that the module is loaded
	extern ubyte _kernelLMA;

	// The beginning of the kernel code (past the bootstrap)
	extern ubyte _kernel;

	// The region of the .data section
	extern ubyte _data;
	extern ubyte _edata;

	// The virtual address where the kernel is loaded
	extern ubyte _kernelVMA;

	// The region of the .text section
	extern ubyte _text;
	extern ubyte _etext;

	// The region of the .bss section
	extern ubyte _bss;
	extern ubyte _ebss;

	extern ubyte _trampoline;
	extern ubyte _etrampoline;
}

// Just provides wrappers to access this information;
struct LinkerScript {
static:
public:

	void* ekernel() {
		return &_ekernel;
	}

	void* kernelLMA() {
		return &_kernelLMA;
	}

	void* kernelVMA() {
		return &_kernelVMA;
	}

	void* kernel() {
		return &_kernel;
	}

	void* data() {
		return &_data;
	}

	void* edata() {
		return &_edata;
	}

	void* text() {
		return &_text;
	}

	void* etext() {
		return &_etext;
	}

	void* bss() {
		return &_bss;
	}

	void* ebss() {
		return &_ebss;
	}

	void* trampoline() {
		return &_trampoline;
	}

	void* etrampoline() {
		return &_etrampoline;
	}

private:
}

