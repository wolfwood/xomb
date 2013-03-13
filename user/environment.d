module user.environment;

import user.util;

public import user.types;

version(KERNEL){
	import kernel.mem.pageallocator;
}else{
	import libos.console;
}


// --- Constants ---
const PageLevel!(4)* root = cast(PageLevel!(4)*)0xFFFFFF7F_BFDFE000;


// --- Paging Structures ---

// The x86 implements a four level page table.
// We use the 4KB page size hierarchy

// The levels are defined here, many are the same but they need
// to be able to be typed differently so we don't make a stupid
// mistake.

template PageTableEntry(char[] T){
	struct PageTableEntry{
		ulong pml;

		static if(T == "primary"){
			mixin(Bitfield!(pml,
											"present", 1,
											"rw", 1,
											"us", 1,
											"pwt", 1,
											"pcd", 1,
											"a", 1,
											"d", 1,
											"pat", 1,
											"g", 1,
											"avl", 3,
											"address", 40,
											"available", 11,
											"nx", 1));
		}else static if(T == "secondary"){
				mixin(Bitfield!(pml,
												"present", 1,
												"rw", 1,
												"us", 1,
												"pwt", 1,
												"pcd", 1,
												"a", 1,
												"ign", 1,
												"mbz", 2,
												"avl", 3,
												"address", 40,
												"available", 11,
												"nx", 1));
			}else{
				static assert(false);
			}

		PhysicalAddress location() {
			return cast(PhysicalAddress)(cast(ulong)address() << 12);
		}

		AccessMode getMode(){
			AccessMode mode;

			if(present){
				if(rw){
					mode |= AccessMode.Writable;
				}
				if(us){
					mode |= AccessMode.User;
				}
				if(!nx){
					mode |= AccessMode.Executable;
				}

				mode |= available;
			}

			return mode;
		}

		version(KERNEL){
			void setMode(AccessMode mode){
				present = 1;
				available = mode & AccessMode.AvailableMask;

				if(mode & AccessMode.Writable){
					rw = 1;
				}else{
					rw = 0;
				}

				if(mode & AccessMode.User){
					us = 1;
				}else{
					us = 0;
				}

				if(mode & AccessMode.Executable){
					nx = 0;
				}else{
					nx = 1;
				}

				static if(T == "primary"){
					if(mode & AccessMode.Device){
						pcd = 1;
					}
				}
			}
		}
	}
}

template PageLevel(ushort L){
	struct PageLevel{
		alias L level;

		static if(L == 1){
			void* physicalAddress(uint idx) {
				if(!entries[idx].present){
					return null;
				}

				return cast(void*)(entries[idx].address << 12);
			}

			ubyte* startingAddressForSegment(uint idx){
				auto tableAddr = this;

				ulong vAddr = (cast(ulong)tableAddr) >> 3;

				vAddr += idx;

				vAddr <<= 12;

				// ensure address is canonical, sign extend the highest meaningful bit
				if(vAddr & 0x00008000_00000000){
					vAddr |= 0xFFFF0000_00000000;
				}else{
					vAddr &= 0x0000FFFF_FFFFFFFF;
				}
				return cast(ubyte*)vAddr;
			}

			//private:
			PageTableEntry!("primary")[512] entries;

		}else{
			PageLevel!(L-1)* getTable(uint idx) {
				if (entries[idx].present == 0) {
					return null;
				}

				return calculateVirtualAddress(idx);
			}

			version(KERNEL){
				void setTable(uint idx, PhysicalAddress address, bool usermode = false) {
					entries[idx].pml = cast(ulong)address;
					entries[idx].present = 1;
					entries[idx].rw = 1;
					entries[idx].us = usermode;
				}

				PageLevel!(L-1)* getOrCreateTable(uint idx, bool usermode = false) {
					PageLevel!(L-1)* ret = getTable(idx);

					if (ret is null) {
						// Create Table
						ret = cast(PageLevel!(L-1)*)PageAllocator.allocPage();

						if(ret is null){
							return null;
						}


						// Set table entry
						entries[idx].pml = cast(ulong)ret;
						entries[idx].present = 1;
						entries[idx].rw = 1;
						entries[idx].us = usermode;

						ret = calculateVirtualAddress(idx);

						*ret = (PageLevel!(L-1)).init;
					}

					return ret;
				}
			}

			ubyte* startingAddressForSegment(uint idx){
				auto tableAddr = calculateVirtualAddress(idx);

				ulong vAddr = (cast(ulong)tableAddr) << ((L-1) * 9);

				// ensure address is canonical, sign extend the highest meaningful bit
				if(vAddr & 0x00008000_00000000){
					vAddr |= 0xFFFF0000_00000000;
				}else{
					vAddr &= 0x0000FFFF_FFFFFFFF;
				}
				return cast(ubyte*)vAddr;
			}


			PageTableEntry!("secondary")[512] entries;

		private:
			PageLevel!(L-1)* calculateVirtualAddress(uint idx){
				static if(L == 4){
					return cast(PageLevel!(L-1)*)(0xFFFFFF7F_BFC00000 + (idx << 12));
				}else static if(L == 3){
						ulong baseAddr = cast(ulong)this;
						baseAddr &= 0x1FF000;
						baseAddr >>= 3;
						return cast(PageLevel!(L-1)*)(0xFFFFFF7F_80000000 + ((baseAddr + idx) << 12));
				}else static if(L == 2){
						ulong baseAddr = cast(ulong)this;
						baseAddr &= 0x3FFFF000;
						baseAddr >>= 3;
						return cast(PageLevel!(L-1)*)(0xFFFFFF00_00000000 + ((baseAddr + idx) << 12));
				}
			}
		} // end static if


	public:
		template walk(alias U, S...){
			void walk(ulong addr, ref S s){
				ulong idx;

				getNextIndex(addr, idx);

				if(U(this, idx, s)){

					static if(L != 1){
						this.getTable(idx).walk!(U)(addr, s);
					}
				}
			}
		}

		template traverse(alias PRE, alias POST, S...){
			bool traverse(ulong startAddr, ulong endAddr, ref S s){
				ulong startIdx, endIdx;

				getNextIndex(startAddr, startIdx);
				getNextIndex(endAddr, endIdx);

				for(uint i = startIdx; i <= endIdx; i++){
					ulong frontAddr, backAddr;

					if(i == startIdx){
						frontAddr = startAddr;
					}else{
						frontAddr = 0;
					}

					if(i == endIdx){
						backAddr = endAddr;
					}else{
						backAddr = ~0UL;
					}

					TraversalDirective directive = TraversalDirective.Descend;
					static if(!is(PRE == noop)){
						directive = PRE(this, i, startIdx, endIdx, s);
					}

					static if(L != 1){
						if(directive == TraversalDirective.Descend){
							auto childTable = this.getTable(i);

							if(childTable !is null){
								bool stop = childTable.traverse!(PRE,POST)(frontAddr, backAddr, s);

								if(stop){
									return true;
								}
							}
						}else if(directive == TraversalDirective.Stop){
							return true;
						}
					}else{
						if(directive == TraversalDirective.Stop){
							return true;
						}
					}

					static if(!is(POST == noop)){
						POST(this, i, startIdx, endIdx, s);
					}
				}

				return false;
			}// end travesal()
		}

	}
}


// --- Arch-dependent Helper Functions ---
AccessMode combineModes(AccessMode a, AccessMode b){
	AccessMode and, or;

	and = a & b & ~AccessMode.AvailableMask;
	or = (a | b) & AccessMode.AvailableMask;

	return and | or;
}

ubyte* createAddress(ulong indexLevel1, ulong indexLevel2, ulong indexLevel3, ulong indexLevel4) {
	ulong vAddr = 0;

	if(indexLevel4 >= 256){
		vAddr = ~vAddr;
		vAddr <<= 9;
	}

	vAddr |= indexLevel4 & 0x1ff;
	vAddr <<= 9;

	vAddr |= indexLevel3 & 0x1ff;
	vAddr <<= 9;

	vAddr |= indexLevel2 & 0x1ff;
	vAddr <<= 9;

	vAddr |= indexLevel1 & 0x1ff;
	vAddr <<= 12;

	return cast(ubyte*) vAddr;
}

// alternative translate address helper, good for recursive functions
void getNextIndex(ref AddressFragment addr, out ulong idx){
	idx = (addr & 0xff8000000000) >> 39;
	addr <<= 9;
}

// turn a normal address into a global address
AddressFragment getGlobalAddress(AddressFragment addr){
	addr >>= 9;
	addr &= ~0xff8000000000UL;
	addr |= (509UL << 39);

	return addr;
}

uint sizeToPageLevel(ulong size){
	uint pagelevel;
	ulong limit;
	for(pagelevel = 1, limit = 4096; ; pagelevel++, limit *= 512){
		if(pagelevel > 4){
			// size is too big
			return 0;
		}

		if(size <= limit){
			return pagelevel;
		}
	}
}


// --- Templated Helpers ---
bool isValidAddress(ubyte* vAddr){
	bool valid = true;

	root.walk!(isValidAddressHelper)(cast(ulong)vAddr, valid);

	return valid;
}

template isValidAddressHelper(T){
	bool isValidAddressHelper(T table, uint idx, ref bool valid){
		if(table.entries[idx].present){
			return true;
		}
		valid = false;
		return false;
	}
}

AccessMode modesForAddress(ubyte* vAddr){
	AccessMode flags;

	root.walk!(modesForAddressHelper)(cast(ulong)vAddr, flags);

	return flags;
}

template modesForAddressHelper(T){
	bool modesForAddressHelper(T table, uint idx, ref AccessMode flags){
		if(table.entries[idx].present){
			if(!flags){
				flags = table.entries[idx].getMode();
			}else{
				flags = combineModes(flags, table.entries[idx].getMode());
			}
			return true;
		}
		return false;
	}
}

PhysicalAddress virt2phys(ubyte* virtAddy){
	ulong bits = cast(ulong)virtAddy & 0xFFF;
	return cast(PhysicalAddress)(cast(ulong)getPhysicalAddressOfPage(virtAddy) | bits);
}

PhysicalAddress getPhysicalAddressOfPage(ubyte* vAddr){
	PhysicalAddress physAddr;

	root.walk!( getPhysicalAddressOfPageHelper)(cast(ulong)vAddr, physAddr);

	return physAddr;
}

template getPhysicalAddressOfPageHelper(T){
	bool getPhysicalAddressOfPageHelper(T table, uint idx, ref PhysicalAddress physAddr){
		if(table.entries[idx].present){
			if(T.level == 1){
				physAddr = table.entries[idx].location();
				return false;
			}

			return true;
		}
		return false;
	}
}


// gets the physical address of a segment of a known size (regardless of nesting)
template getPhysicalAddressOfSegment(T){
	PhysicalAddress getPhysicalAddressOfSegment(ubyte* vAddr){
		PhysicalAddress physAddr;
		T levelOfSegment;

		root.walk!(getPhysicalAddressOfSegmentHelper)(cast(AddressFragment)vAddr, physAddr, levelOfSegment);

		return physAddr;
	}
}

template getPhysicalAddressOfSegmentHelper(T, U){
	bool getPhysicalAddressOfSegmentHelper(T table, uint idx, ref PhysicalAddress physAddr, ref U levelOfSegment){
		if(table.entries[idx].present){
			static if(is(T == U)){
				if(table.entries[idx].getMode() & (AccessMode.Segment|AccessMode.RootPageTable)){
					physAddr = table.entries[idx].location();
				}
				return false;
			}
			return true;
		}
		return false;
	}
}

// return the physical address of the first (largest) segment it stumbles upon
PhysicalAddress findPhysicalAddressOfAddressSpace(ubyte* vAddr){
	PhysicalAddress physAddr;

	root.walk!(findPhysicalAddressOfAddressSpaceHelper)(cast(AddressFragment)vAddr, physAddr);

	return physAddr;
}

template findPhysicalAddressOfAddressSpaceHelper(T){
	bool findPhysicalAddressOfAddressSpaceHelper(T table, uint idx, ref PhysicalAddress physAddr){
		if(table.entries[idx].present){
			if(table.entries[idx].getMode() & AccessMode.RootPageTable){
				physAddr = table.entries[idx].location();
				return false;
			}else{
				return true;
			}
		}
		return false;
	}
}

ubyte[] findFreeSegment(bool upperhalf = true, ulong size = oneGB){
	ubyte* vAddr;
	ulong startAddr, endAddr;

	uint pagelevel = sizeToPageLevel(size);

	if(pagelevel == 0){
		return null;
	}

	if(upperhalf){
		// only search kernel's segment
		startAddr = cast(ulong)createAddress(0,0,0,256);
		endAddr = cast(ulong)createAddress(511,511,511,256);
	}else{
		startAddr = cast(ulong)createAddress(0,0,1,0);
		endAddr = cast(ulong)createAddress(511,511,511,255);
	}

	// global
	//startAddr = createAddr(0,0,0,257);
	//endAddr = createAddr(511,511,511,508);

	switch(pagelevel){
	case 1:
		PageLevel!(1)* segmentParent;
		root.traverse!(preorderFindFreeSegmentHelper, noop)(startAddr, endAddr, vAddr, segmentParent);
		break;
	case 2:
		PageLevel!(2)* segmentParent;
		root.traverse!(preorderFindFreeSegmentHelper, noop)(startAddr, endAddr, vAddr, segmentParent);
		break;
	case 3:
		PageLevel!(3)* segmentParent;
		root.traverse!(preorderFindFreeSegmentHelper, noop)(startAddr, endAddr, vAddr, segmentParent);
		break;
	case 4:
		PageLevel!(4)* segmentParent;
		root.traverse!(preorderFindFreeSegmentHelper, noop)(startAddr, endAddr, vAddr, segmentParent);
		break;
	}
	return vAddr[0..size];
}

template preorderFindFreeSegmentHelper(T, PL){
	TraversalDirective preorderFindFreeSegmentHelper(T table, uint idx, uint startIdx, uint endIdx, ref ubyte* vAddr, ref PL segmentParent){
		// are we at the proper depth to allocate the desired segment?
		static if(is(T == PL)){
			// is present?
			if(!table.entries[idx].present){
				vAddr = table.startingAddressForSegment(idx);
				return TraversalDirective.Stop;
			}

			return TraversalDirective.Skip;
		}else{
			static if(T.level != 1){
				auto next = table.getTable(idx);

				// we can't allocate page tables in userspace (and don't need
				// to), so instead of descending we assume 0 for the remaining
				// indexes and stop
				if(next is null){
					vAddr = table.startingAddressForSegment(idx);
					return TraversalDirective.Stop;
				}
			}

			// if entry is for a gib, we can't allocate inside
			if(table.entries[idx].getMode() & AccessMode.Segment){
				return TraversalDirective.Skip;
			}

			return TraversalDirective.Descend;
		}
	}
}

// --- table manipulation templates ---

// use this to skip pre or post traversal execution
template noop(K...){TraversalDirective noop(K k){return TraversalDirective.Descend;}}

enum TraversalDirective {
	Descend,
	Skip,
	Stop
}
