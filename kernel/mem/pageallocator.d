/*
 * pageallocator.d
 *
 * This module abstracts the page allocator for the kernel.
 *
 */

module kernel.mem.pageallocator;

// Import system info to get info about RAM layout
import kernel.system.info;

// Import architecture dependent foo
import architecture.vm;
import architecture.perfmon;

// Import kernel foo
import kernel.core.kprintf;
import kernel.core.log;
import kernel.core.error;

// Import the configurable allocator
import kernel.config : PageAllocatorImplementation;

struct PageAllocator {
static:
public:

	ErrorVal initialize() {
		ErrorVal ret = PageAllocatorImplementation.initialize();
		_initialized = true;
		return ret;
	}

	ErrorVal reportCore() {
		return PageAllocatorImplementation.reportCore();
	}

	void* allocPage() {
		if (!_initialized) {
			if (_start is null) {
				_start = System.kernel.start + System.kernel.length;
				_start = cast(ubyte*)(cast(ulong)_start / cast(ulong)VirtualMemory.getPageSize());
				_start = cast(ubyte*)((cast(ulong)_start+1) * cast(ulong)(VirtualMemory.getPageSize()));
				// Make _start appear AFTER all modules.
				for(size_t i = 0; i < System.numModules; i++) {
					// Get the bounds of the module on a page alignment.
					ubyte* regionAddr = cast(ubyte*)System.moduleInfo[i].start;
					ubyte* regionEdge = cast(ubyte*)(cast(ulong)(regionAddr + System.moduleInfo[i].length) / cast(ulong)VirtualMemory.getPageSize());
					regionEdge = cast(ubyte*)((cast(ulong)regionEdge + 1) * cast(ulong)(VirtualMemory.getPageSize()));
					if (_start < regionEdge) {
						_start = regionEdge;
					}
				}
				_curpos = _start;
			}

			// Simply allocate the next page
			ubyte* ret = _curpos;
			_curpos += VirtualMemory.getPageSize();
			return ret;
		}
		return PageAllocatorImplementation.allocPage();
	}

	void* allocPage(void* virtualAddress) {
		if (!_initialized) {
			// Shouldn't invoke allocPage for virtual addresses
			// until the allocator is initialized.
			// XXX: Panic.
			return null;
		}
		return PageAllocatorImplementation.allocPage(virtualAddress);
	}

	ErrorVal freePage(void* physicalAddress) {
		if (!_initialized) {
			// Cannot do anything.
			return ErrorVal.Fail;
		}
		return PageAllocatorImplementation.freePage(physicalAddress);
	}

	uint length() {
		return 0;
	}

	ubyte* start() {
		return null;
	}

	ubyte* virtualStart() {
		return null;
	}

package:

	// Whether or not this module has been initialized.
	bool _initialized = false;

	ubyte* _start = null;
	ubyte* _curpos = null;
}
