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

align(4096) struct Bogo{
	ubyte[4096*2] data;
}

Bogo foo;
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

	void* allocPage() {
		if (!_initialized) {
			if (_start is null) {
				// Make _start appear somewhere reasonable
				// In this case, make sure it is at the start of a 16MB section of RAM
				static const PREINITIALIZED_BUFFER_SIZE = 16 * 1024 * 1024;

				// Assume first that we need to start at the end of the kernel
				_start = System.kernel.start + System.kernel.length;
				_start = cast(ubyte*)(cast(ulong)_start / cast(ulong)VirtualMemory.pagesize());
				_start = cast(ubyte*)((cast(ulong)_start+1) * cast(ulong)(VirtualMemory.pagesize()));

				// Now look for Modules that are in our way of that 16MB
				for(size_t i = 0; i < System.numModules; i++) {
					// Get the bounds of the module on a page alignment.
					ubyte* regionAddr = cast(ubyte*)System.moduleInfo[i].start;
					ubyte* regionEdge = cast(ubyte*)(cast(ulong)(regionAddr + System.moduleInfo[i].length) / cast(ulong)VirtualMemory.pagesize());
					regionEdge = cast(ubyte*)((cast(ulong)regionEdge + 1) * cast(ulong)(VirtualMemory.pagesize()));

					if (_start + PREINITIALIZED_BUFFER_SIZE > regionAddr) {
						// If it is intruding, place at the end of the Module
						_start = regionEdge;
					}
				}
				_curpos = _start;
			}

			// Simply allocate the next page
			ubyte* ret = _curpos;
			_curpos += VirtualMemory.pagesize();
			return ret;
		}

		//void* mapping = cast(void*)((cast(ulong)foo.data.ptr + 4096UL) & (0xFFFFFFFF_FFFFF000UL));

		void* ptr = PageAllocatorImplementation.allocPage();

		//VirtualMemory.mapRegion(null, ptr, 4096, mapping, true);
		
		//VirtualMemory.mapPage(ptr, mapping);

		//void* mapping = VirtualMemory.mapKernelPage(ptr);
		//memset(mapping, 0, 4096);

		return ptr;
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
