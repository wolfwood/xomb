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
	ubyte[] createSegment(ulong size, uint flags) {
		ubyte* location = null;

		Paging.createGib(location, size, flags);

		return location[0 .. size];
	}

	// Open a segment indicated by location into the
	// virtual address space of dest.
	bool openSegment(AddressSpace dest, ubyte* location, uint flags) {
		if (dest !is null) {
			// Hmm, we need to open this in another address space.
			return false;
		}
		else {
			// We should open this in our address space.
			return Paging.openGib(location, flags);
		}
	}

	bool mapSegment(AddressSpace dest, ubyte* location, ubyte* destination, uint flags) {
		return false;
	}

	bool closeSegment(ubyte* location) {
		return Paging.closeGib(location);
	}

	// -- Address Spaces -- //

	// Create a virtual address space.
	AddressSpace createAddressSpace() {
		return null;
	}

	// --- OLD --- //

	ubyte* allocGib(out ubyte* location, uint gibIndex, uint flags) {
		return Paging.allocGib(location, gibIndex, flags);
	}

	ubyte* openGib(ubyte* address, uint gibIndex, uint flags) {
		return Paging.openGib(address, gibIndex, flags);
	}

	// This function will take the "gibSrc" specified and map it to the gib determined by "gibDest".
	synchronized ErrorVal mapGib(void* gibSrc, void* gibDest) {
		return Paging.mapGib(gibSrc, gibDest);
	}

	synchronized ErrorVal mapRegion(void* gib, void* physAddr, ulong regionLength) {
		return Paging.mapRegion(gib, physAddr, regionLength);
	}

	// The page size we are using
	uint pagesize() {
		return Paging.PAGESIZE;
	}

	// This function will translate a virtual address to a physical address.
	synchronized void* translate(void* address) {
		return Paging.translateAddress(address);
	}

	// This function will map a region to the region space starting at
	// physAdd across a length of regionLength.
	synchronized void* mapRegion(void* physAddr, ulong regionLength) {
		return Paging.mapRegion(physAddr, regionLength);
	}

	//
	synchronized void* mapKernelPage(void* physAddr) {
		return Paging.mapRegion(physAddr, 4096);
	}

	// This function will map a single page at the specified physical address
	// to the specifed virtual address.
	synchronized ErrorVal mapPage(void* physAddr, void* virtAddr) {
		return ErrorVal.Success;
	}

	// This function will map a range of data located at the physical
	// address across a range of a specifed length to the virtual
	// region starting at virtual address.
	synchronized ErrorVal mapRange(void* physAddr, ulong rangeLength, void* virtAddr) {
		return ErrorVal.Success;
	}

	// This function will unmap a page at the virtual address specified.
	synchronized ErrorVal unmapPage(void* virtAddr) {
		return ErrorVal.Success;
	}

	// This function will unmap a range of data. Give the length in bytes.
	synchronized ErrorVal unmapRange(void* virtAddr, ulong rangeLength) {
		return ErrorVal.Success;
	}
}
