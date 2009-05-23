/*
 * cpu.d
 *
 * This module defines the interface for speaking to the Cpu
 *
 */

module kernel.arch.x86.cpu;

// Import Arch Modules
// TODO: all of this

// To return error values
import kernel.core.error;
import kernel.core.log;
import kernel.core.kprintf;

struct Cpu
{
static:
public:

	// This module will conform to the interface
	ErrorVal initialize()
	{
		return ErrorVal.Success;
	}
}
