/*
 * vm.d
 *
 * This file implements the virtual memory interface needed by the
 * architecture dependent bridge
 *
 */

module architecture.vm;

// All of the paging calls
import kernel.arch.x86_64.core.paging;

// Normal kernel modules
import kernel.core.error;

import user.environment;

class VirtualMemory {
static:
public:

	// -- Initialization -- //

	ErrorVal initialize() {
		// Install Virtual Memory and Paging
		return Paging.initialize();
	}

	ErrorVal install() {
		return Paging.install();
	}

	// -- Segment Handling -- //

	// Create a new segment that will fit the indicated size
	// into the global address space.
	ubyte[] createSegment(ubyte* location, ulong size, AccessMode flags) {
		Paging.createGib(location, size, flags);

		return location[0 .. size];
	}

	// Open a segment indicated by location into the
	// virtual address space of dest.
	bool openSegment(ubyte* location, AccessMode flags) {
		// We should open this in our address space.
		return Paging.openGib(location, flags);
	}

	bool mapSegment(AddressSpace dest, ubyte* location, ubyte* destination, AccessMode flags) {
		Paging.mapGib(dest, location, destination, flags);
		return false;
	}

	bool closeSegment(ubyte* location) {
		return Paging.closeGib(location);
	}

	// -- Address Spaces -- //

	// Create a virtual address space.
	AddressSpace createAddressSpace() {
		return Paging.createAddressSpace();
	}

	ErrorVal switchAddressSpace(AddressSpace as = null){
		return Paging.switchAddressSpace(as);
	}

	public import user.environment : findFreeSegment;

	// The page size we are using
	uint pagesize() {
		return Paging.PAGESIZE;
	}

	synchronized void* mapStack(void* physAddr) {
		if(stackSegment is null){
			stackSegment = findFreeSegment();
			Paging.createGib(stackSegment, oneGB, AccessMode.Kernel|AccessMode.Writable);
		}

		stackSegment += Paging.PAGESIZE;

		if(Paging.mapRegion(stackSegment, physAddr, Paging.PAGESIZE) == ErrorVal.Fail){
			return null;
		}else{
			return stackSegment;
		} 
	}

	// --- OLD --- //
	synchronized ErrorVal mapRegion(void* gib, void* physAddr, ulong regionLength) {
		return Paging.mapRegion(gib, physAddr, regionLength);
	}

private:
	ubyte* stackSegment;
}
