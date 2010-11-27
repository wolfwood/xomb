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

		// XXX: handle global and different sizes!
	template findFreeSegment(bool upperhalf = true, bool global = false, uint size = 1024*1024*1024){
		ubyte* findFreeSegment(){
			const uint dividingLine = 256;
			static uint last1 = (upperhalf ? dividingLine : 1), last2 = 0;
			
			bool foundFree;
			void* addy;

			while(!foundFree){
				PageLevel3* pl3 = Paging.root.getTable(last1);

				if(pl3 is null){
					addy = Paging.createAddress(0, 0, 0, last1);
					last2 = 1;
					break;
				}

				while(!foundFree && last2 < pl3.entries.length){
					if(pl3.entries[last2].pml == 0){
						foundFree = true;
						addy = Paging.createAddress(0, 0, last2, last1);
					}
					last2++;
				}

				if(last2 >= pl3.entries.length){
					last1++;
					last2 = 0;
				}

				if(upperhalf){
					if(last1 >= Paging.root.entries.length){
						last1 = dividingLine;
					}
				}else{
					if(last1 >= dividingLine){
						last1 = 1;
					}

				}

			}
			
			assert(addy !is null, "null gib find fail\n");

			return cast(ubyte*)addy;
		}
	}

	// The page size we are using
	uint pagesize() {
		return Paging.PAGESIZE;
	}

	// --- OLD --- //

	ubyte* allocGib(out ubyte* location, uint gibIndex, uint flags) {
		return Paging.allocGib(location, gibIndex, flags);
	}

	ubyte* openGib(ubyte* address, uint gibIndex, uint flags) {
		return Paging.openGib(address, gibIndex, flags);
	}

	synchronized ErrorVal mapRegion(void* gib, void* physAddr, ulong regionLength) {
		return Paging.mapRegion(gib, physAddr, regionLength);
	}


	//
	synchronized void* mapKernelPage(void* physAddr) {
		return Paging.mapRegion(physAddr, 4096);
	}
	
}
