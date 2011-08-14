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
import architecture.cpu;

// To return error values
import kernel.core.error;
import kernel.core.log;
import kernel.core.kprintf;

import kernel.dev.console;

// We need some values from the linker script
import kernel.arch.x86_64.linker;

// To set some values in the core table
import kernel.system.info;

struct Architecture {
static:
public:

	// This function will initialize the architecture upon boot
	ErrorVal initialize() {
		// Reading from the linker script
		// We want the length of the kernel module
		System.kernel.start = null;
		System.kernel.length = LinkerScript.ekernel - LinkerScript.kernelVMA;
		System.kernel.virtualStart = cast(ubyte*)LinkerScript.kernelVMA;

		// Global Descriptor Table
		Log.print("Architecture: Initializing GDT");
	   	Log.result(GDT.initialize());

		// Task State Segment
		Log.print("Architecture: Initializing TSS");
		Log.result(TSS.initialize());

		// Interrupt Descriptor Table
		Log.print("Architecture: Initializing IDT");
		Log.result(IDT.initialize());

		Log.print("Cpu: Polling Cache Info");
		Log.result(Cpu.getCacheInfo());

		Console.switchToHigherHalfVirtualAddress();

		// Everything must have succeeded
		return ErrorVal.Success;
	}
}

