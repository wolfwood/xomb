/*
 * mp.d
 *
 * This module contains the abstraction for the Multiprocessor module
 *
 */

module kernel.arch.x86.mp;

// Import architecture stuffs
// TODO: all of this

// MP Spec
// TODO: all of this

// Import helpful routines
import kernel.core.error;	// ErrorVal
import kernel.core.log;		// logging

struct Multiprocessor
{
static:
public:

	// This module will conform the the interface
	ErrorVal initialize()
	{
		return ErrorVal.Success;
	}
private:
}
