/*
 * main.d
 *
 * This module contains the boot and initialization logic
 * for an architecture
 *
 */

module architecture.main;

// import normal architecture dependencies
import kernel.arch.x86_64.core.gdt;
import kernel.arch.x86_64.core.tss;
import kernel.arch.x86_64.core.idt;
import kernel.arch.x86_64.core.paging;
import architecture.syscall;

// To return error values
import kernel.core.error;
import kernel.core.log;
import kernel.core.kprintf;

import kernel.dev.console;

// We need some values from the linker script
import kernel.arch.x86_64.linker;

// To set some values in the core table
import kernel.system.info;

// We need to set up the page allocator
import kernel.mem.heap;

struct Architecture
{
static:
public:

	// This function will initialize the architecture upon boot
	ErrorVal initialize() {
		// Read from the linker script
		// We want the length of the kernel module
		System.kernel.start = cast(ubyte*)0x0;
		System.kernel.length = LinkerScript.ekernel - LinkerScript.kernelVMA;
		System.kernel.virtualStart = cast(ubyte*)LinkerScript.kernelVMA;

		// Global Descriptor Table
		printToLog("Architecture: Initializing GDT", GDT.initialize());

		// Task State Segment
		printToLog("Architecture: Initializing TSS", TSS.initialize());

		// Interrupt Descriptor Table
		printToLog("Architecture: Initializing IDT", IDT.initialize());

		Console.virtualAddress = cast(void*)(cast(ubyte*)System.kernel.virtualStart + 0xB8000);

		// Everything must have succeeded
		return ErrorVal.Success;
	}
}

