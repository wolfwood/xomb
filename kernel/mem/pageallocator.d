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

/*
extern(C) void memset(void*, int, uint);
*/

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

	PhysicalAddress allocPage() {
		if (!_initialized) {
		  // Make _start appear somewhere reasonable
		  // In this case, make sure it is at the start of a 16MB section of RAM
		  static const PREINITIALIZED_BUFFER_SIZE = 64 * 1024 * 1024;

			if (_start is null) {

				// Assume first that we need to start at the end of the kernel
				_start = cast(PhysicalAddress)System.kernel.start + System.kernel.length;
				_start = cast(PhysicalAddress)(cast(ulong)_start / cast(ulong)VirtualMemory.pagesize());
				_start = cast(PhysicalAddress)((cast(ulong)_start+1) * cast(ulong)(VirtualMemory.pagesize()));

				// Now look for Modules that are in our way of that 16MB
				for(size_t i = 0; i < System.numModules; i++) {
					// Get the bounds of the module on a page alignment.
					PhysicalAddress regionAddr = cast(PhysicalAddress)System.moduleInfo[i].start;
					PhysicalAddress regionEdge = cast(PhysicalAddress)(cast(ulong)(regionAddr + System.moduleInfo[i].length) / cast(ulong)VirtualMemory.pagesize());
					regionEdge = cast(PhysicalAddress)((cast(ulong)regionEdge + 1) * cast(ulong)(VirtualMemory.pagesize()));

					if (_start + PREINITIALIZED_BUFFER_SIZE > regionAddr) {
						// If it is intruding, place at the end of the Module
						_start = regionEdge;
					}
				}
				_curpos = _start;
			}

			// Simply allocate the next page
			PhysicalAddress ret = _curpos;
			_curpos += VirtualMemory.pagesize();

			if((_start + PREINITIALIZED_BUFFER_SIZE) < _curpos){
			  kprintfln!("{} {} {x}")(cast(ubyte*)_start, cast(ubyte*)_curpos, PREINITIALIZED_BUFFER_SIZE);
			  assert(1 == 0);
			}
			return ret;
		}

		PhysicalAddress ptr = PageAllocatorImplementation.allocPage();

		return ptr;
	}

	PhysicalAddress allocPage(void* virtualAddress) {
		if (!_initialized) {
			// Shouldn't invoke allocPage for virtual addresses
			// until the allocator is initialized.
			// XXX: Panic.
			return null;
		}
		return PageAllocatorImplementation.allocPage(virtualAddress);
	}

	ErrorVal freePage(PhysicalAddress physicalAddress) {
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

	PhysicalAddress _start = null;
	PhysicalAddress _curpos = null;
}
