/*
 * main.d
 *
 * This module contains the boot and initialization logic
 * for an architecture
 *
 */

module kernel.arch.x86.main;

// import normal architecture dependencies
// TODO: all of this

// To return error values
import kernel.core.error;
import kernel.core.log;
import kernel.core.kprintf;

// We need some values from the linker script
import kernel.arch.x86.linker;

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
		// Everything must have succeeded
		return ErrorVal.Success;
	}
}

