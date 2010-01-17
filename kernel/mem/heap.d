/*
 * heap.d
 *
 * This module implements the kernel heap to allocate dynamic memory.
 *
 */

module kernel.mem.heap;

// Import system info to get info about RAM
import kernel.system.info;

// Import architecture dependent foo
import architecture.vm;
import architecture.perfmon;

// Import kernel foo
import kernel.core.kprintf;
import kernel.core.log;
import kernel.core.error;

// The Heap needs a Gib.
import kernel.mem.giballocator;
import kernel.mem.gib;

// Import the configurable allocator
import kernel.config : HeapImplementation;

struct Heap {
static:
public:

	// Needs to be called by the architecture
	ErrorVal initialize() {
		_gib = GibAllocator.alloc((1024*128)+2, 0);
		return ErrorVal.Success;
	}

	// Needs to be called by each core (including boot)
	ErrorVal reportCore() {
		return ErrorVal.Success;
	}

	uint length() {
		return 0;
	}

private:

	Gib _gib;

	// Whether or not this module has been initialized
	bool _initialized;
}
