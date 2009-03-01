/*
 * main.d
 *
 * This module contains the boot and initialization logic
 * for an architecture
 *
 */

module kernel.arch.x86_64.main;

import kernel.arch.x86_64.core.gdt;
import kernel.arch.x86_64.core.tss;
import kernel.arch.x86_64.core.idt;

// To return error values
import kernel.core.error;
import kernel.core.log;

// This function will initialize the architecture upon boot
ErrorVal archInitialize()
{
	printToLog("Initializing GDT", GDT.initialize());
	printToLog("Initializing TSS", TSS.initialize());
	printToLog("Initializing IDT", IDT.initialize());
	//printToLog("", );

	return ErrorVal.Success;
}

