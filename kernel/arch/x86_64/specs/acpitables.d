/*
 * acpitables.d
 *
 * This module contains the logic to find and parse the ACPI Tables
 *
 */

module kernel.arch.x86_64.specs.acpitables;

// Useful kernel imports
import kernel.core.error;
import kernel.core.log;
import kernel.core.kprintf;

struct Tables
{
static:
public:

	// For the multiprocessor initialization.
	// Will return true when the appropriate table is found.
	ErrorVal findTable()
	{
		return ErrorVal.Fail;
	}

	ErrorVal readTable()
	{
		return ErrorVal.Fail;
	}

private:

}
