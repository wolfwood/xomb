/*
 * heap.d
 *
 * This module implements the kernel heap page allocator.
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

// Import the configurable allocator
import kernel.config : HeapImplementation;

/*

   The Heap will be placed in virtual space directly after the virtual space
   taken up by the kernel (kernel.virtualStart + kernel.length).

   The Architecture initialization will be responsible for reporting the
   length and virtual address of the kernel. The architecture will need to
   allot space for the bitmap and have a direct mapping to RAM for the Heap
   to initialize.

   The Heap can be asked its location via the 'start' and 'virtualStart'
   functions. When VirtualMemory is initialized, it will need to make
   sure a mapping exists for Heap.start .. Heap.start + Heap.length to
   map to Heap.virtualStart. 

*/

struct Heap {
static:
public:

	// Needs to be called by the architecture
	ErrorVal initialize() {
		// We do not want to reinitialize this module.
		if (initialized) {
			return ErrorVal.Fail;
		}

		// The module has been initialized.
		initialized = true;

		return HeapImplementation.initialize();
	}

	void virtualStart(void* newAddr) {
		HeapImplementation.virtualStart = newAddr;
	}

	// This will allocate a page and return a physical address and will
	// not attempt to map it into virtual memory.
	void* allocPageNoMap(void * virtAddr = null) {
		return HeapImplementation.allocPage(virtAddr);
	}

	// This will allocate a page, and return the virtual address while
	// coordinating with the VirtualMemory module.
	void* allocPage(void * virtAddr = null) {
		// compute physical address
		void* address = allocPageNoMap(virtAddr);

		// map in the region
		return VirtualMemory.mapKernelPage(address);
	}

	void* allocRegion(ulong regionLength) {
		void* ret = allocPage();

		while (regionLength > VirtualMemory.getPageSize) {
			allocPage();
			regionLength -= VirtualMemory.getPageSize();
		}

		return ret;
	}

	// This will free an allocated page, if it is allowed.
	ErrorVal freePage(void* address) {
		return HeapImplementation.freePage(address);
	}

	uint length() {
		return HeapImplementation.length();
	}

	ubyte* start() {
		return HeapImplementation.start();
	}

	ubyte* virtualStart() {
		return HeapImplementation.virtualStart();
	}

private:

	// Whether or not this module has been initialized
	bool initialized;
}
