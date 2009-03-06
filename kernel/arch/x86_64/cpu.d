/*
 * cpu.d
 *
 * This module defines the interface for speaking to the Cpu
 *
 */

module kernel.arch.x86_64.cpu;

// Import Arch Modules
import kernel.arch.x86_64.core.gdt;
import kernel.arch.x86_64.core.tss;
import kernel.arch.x86_64.core.idt;

// To return error values
import kernel.core.error;
import kernel.core.log;
import kernel.core.kprintf;

// This module will conform to the interface
ErrorVal cpuInitialize()
{
	GDT.install();
	printToLog("Enabling GDT", ErrorVal.Success);
	TSS.install();
	printToLog("Enabling TSS", ErrorVal.Success);
	IDT.install();
	printToLog("Enabling IDT", ErrorVal.Success);

	return ErrorVal.Success;
}
