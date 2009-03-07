/*
 * main.d
 *
 * This module contains the boot and initialization logic
 * for an architecture
 *
 */

module kernel.arch.x86_64.main;

// import normal architecture dependencies
import kernel.arch.x86_64.core.gdt;
import kernel.arch.x86_64.core.tss;
import kernel.arch.x86_64.core.idt;

// To return error values
import kernel.core.error;
import kernel.core.log;
import kernel.core.kprintf;

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
	ErrorVal initialize()
	{
		// Read from the linker script
		// We want the length of the kernel module
		System.kernel.start = cast(ubyte*)LinkerScript.kernelLMA;
		System.kernel.length = LinkerScript.ekernel - LinkerScript.kernelVMA;

		// Global Descriptor Table
		printToLog("Initializing GDT", GDT.initialize());

		// Task State Segment
		printToLog("Initializing TSS", TSS.initialize());

		// Interrupt Descriptor Table
		printToLog("Initializing IDT", IDT.initialize());


		// Initialize the system heap, because we will need it
		// XXX: for now
		System.memoryInfo.length = 128 * 1024 * 1024;
		kprintfln!("memlen: {x}")(System.memoryInfo.length);
		kprintfln!("start: {x} + length: {x}")(System.kernel.start, System.kernel.length);
		Heap.initialize(cast(ubyte*)LinkerScript.kernelVMA + cast(ulong)System.kernel.start + System.kernel.length);



		// Everything must have succeeded
		return ErrorVal.Success;
	}
}

