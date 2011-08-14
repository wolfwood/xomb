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

public import user.environment;

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
	ubyte[] createSegment(ubyte[] location, AccessMode flags) {
		bool success;
		uint pagelevel = sizeToPageLevel(location.length);

		switch(pagelevel){
		case 1:
			// create the segment in the AddressSpace
			success = Paging.createGib!(PageLevel!(1))(location.ptr, flags);
			break;
		case 2:
			success = Paging.createGib!(PageLevel!(2))(location.ptr, flags);
			break;
		case 3:
			success = Paging.createGib!(PageLevel!(3))(location.ptr, flags);
			break;
		case 4:
			success = Paging.createGib!(PageLevel!(4))(location.ptr, flags);
			break;
		}

		if(success){
			return location;
		}else{
			return null;
		}
	}

	bool mapSegment(AddressSpace dest, ubyte[] location, ubyte* destination, AccessMode flags) {
		if(location is null){
			return false;
		}

		ErrorVal result;
		uint pagelevel = sizeToPageLevel(location.length);

		switch(pagelevel){
			//case 1:
			//result = Paging.mapGib!(PageLevel!(1))(dest, location.ptr, destination, flags);
			//break;
		case 2:
			result = Paging.mapGib!(PageLevel!(2))(dest, location.ptr, destination, flags);
			break;
		case 3:
			result = Paging.mapGib!(PageLevel!(3))(dest, location.ptr, destination, flags);
			break;
		case 4:
			result = Paging.mapGib!(PageLevel!(4))(dest, location.ptr, destination, flags);
			break;
		default:
			return false;
		}

		if(result == ErrorVal.Success){
			return true;
		}else{
			return false;
		}
	}

	bool closeSegment(ubyte* location) {
		return Paging.closeGib(location);
	}

	// -- Address Spaces -- //

	// Create a virtual address space.
	AddressSpace createAddressSpace() {
		return Paging.createAddressSpace();
	}

	ErrorVal switchAddressSpace(AddressSpace as, out PhysicalAddress oldRoot){
		return Paging.switchAddressSpace(as, oldRoot);
	}

	public import user.environment : findFreeSegment;

	// The page size we are using
	uint pagesize() {
		return Paging.PAGESIZE;
	}

	synchronized ubyte* mapStack(PhysicalAddress physAddr) {
		if(stackSegment is null){
			stackSegment = findFreeSegment();
			createSegment(stackSegment, AccessMode.Writable|AccessMode.AllocOnAccess);
		}

		stackSegment = stackSegment[Paging.PAGESIZE..$];

		return Paging.mapRegion(stackSegment.ptr, physAddr, Paging.PAGESIZE).ptr;
	}

	// --- OLD --- //
	synchronized ErrorVal mapRegion(ubyte* gib, PhysicalAddress physAddr, ulong regionLength) {
		if(Paging.mapRegion(gib, physAddr, regionLength) !is null){
			return ErrorVal.Fail;
		}

		return ErrorVal.Success;
	}

private:
	ubyte[] stackSegment;
}
