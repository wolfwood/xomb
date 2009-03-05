/*
 * mp.d
 *
 * This module contains the abstraction for the Multiprocessor module
 *
 */

module kernel.arch.x86_64.mp;

import kernel.arch.x86_64.core.gdt;
import kernel.arch.x86_64.core.tss;
import kernel.arch.x86_64.core.idt;

// MP Spec
import kernel.arch.x86_64.specs.mp;
import kernel.arch.x86_64.specs.acpi;

// Import helpful routines
import kernel.core.error;	// ErrorVal
import kernel.core.log;		// logging

// This module will conform the the interface
ErrorVal mpInitialize()
{
	// 1. Look for the ACPI tables (preferred method)
	if(ACPI.Tables.findTable() == ErrorVal.Success)
	{
		// ACPI tables found
		return ACPI.Tables.readTable();
	}

	// 2. Fall back on looking for the MP tables

	// 2a. Locate the MP Tables
	if (MP.findTable() == ErrorVal.Fail)
	{
		// If the MP table is missing, fail.
		return ErrorVal.Fail;
	}

	// 2b. Read MP Table
	return MP.readTable();
}
