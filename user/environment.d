module user.environment;

import user.util;
import Syscall = user.syscall;

version(KERNEL){
	import kernel.mem.pageallocator;
}else{
	import libos.console;
}

typedef ubyte* AddressSpace;
typedef ubyte* PhysicalAddress;
alias ulong AddressFragment;

const ulong oneGB = 1024*1024*1024UL;
const PageLevel!(4)* root = cast(PageLevel!(4)*)0xFFFFFF7F_BFDFE000;

// XXX make this a ulong alligned with PTE bits?
enum AccessMode : uint {
	Read = 0,

	// bits that get encoded in the available bits
	Global = 1,
	AllocOnAccess = 2,
	 
	MapOnce = 4,
	CopyOnWrite = 8,

	PrivilegedGlobal = 16,
	PrivilegedExecutable = 32,

	// use Indicators
	Segment = 64,
	RootPageTable = 128,
	Device = 256, // good enough for isTTY?

	// Permissions
	Delete = 512,
	// bits that are encoded in hardware defined PTE bits
	Writable = 1 <<  14,
	User = 1 << 15,
	Executable = 1 << 16,

	// Size? - could be encoded w/ paging trick on address

	// Default policies
	DefaultUser = Writable | AllocOnAccess | User,
	DefaultKernel = Writable | AllocOnAccess,

	// flags that are always permitted in syscalls
	SyscallStrictMask = Global | AllocOnAccess | MapOnce | CopyOnWrite | Writable 
	  | User | Executable,

	// Flags that go in the available bits
	AvailableMask = Global | AllocOnAccess | MapOnce | CopyOnWrite | 
	  PrivilegedGlobal | PrivilegedExecutable | Segment | RootPageTable |
	  Device | Delete
}


// place to store values that must be communicated to the  child process from the parent
struct MessageInAbottle {
	ubyte[] stdin;
	ubyte[] stdout;
	bool stdinIsTTY, stdoutIsTTY;
	char[][] argv;

	int exitCode;

	// assumes alloc on write beyond end of exe
	void setArgv(char[][] parentArgv, ubyte[] to = (cast(ubyte*)oneGB)[0..oneGB]){
		// assumes allocation on write region exists immediately following bottle

		// allocate argv's array reference array first, since we know how long it is
		argv = (cast(char[]*)this + MessageInAbottle.sizeof)[0..parentArgv.length];
		
		// this will be a sliding window for the strngs themselves, allocated after the argv array reference array 
		char[] storage = (cast(char*)argv[length..length].ptr)[0..0];

		foreach(i, str; parentArgv){
			storage = storage[length..length].ptr[0..(str.length+1)]; // allocate an extra space for null terminator

			storage[0..(str.length)] = str[];

			storage[(str.length)] = '\0';  // stick on null terminator

			argv[i] = storage[0..(str.length)];
		}

		// adjust pointers
		adjustArgvPointers(to);
	}
	
	void setArgv(char[] parentArgv,  ubyte[] to = (cast(ubyte*)oneGB)[0..oneGB]){

		// allocate strings first, since we know how long they are
		char[] storage = (cast(char*)this + MessageInAbottle.sizeof)[0..(parentArgv.length +1)];
		
		storage[0..($-1)] = parentArgv[];
		
		// determine length of array reference array
		int substrings = 1;

		foreach(ch; storage){
			if(ch == ' '){
				substrings++;
			}
		}
		
		storage[($-1)] = '\0';

		// allocate array reference array
		argv = (cast(char[]*)storage[length..length].ptr)[0..substrings];

		char* arg = storage.ptr;
		int len, i;

		foreach(ref ch; storage){
			if(ch == ' '){
				ch = '\0';
				argv[i] = arg[0..len];
				len++;
				len++;
				arg = arg[len..len].ptr;
				len = 0;
				i++;
			}else{
				len++;
			}
		}//end foreach

		// final sub array isn't (hopefully) followed by a space, so it
		// will bot get assigned in loop, and we must do it here instead

		argv[i] = (arg)[0..len];

		adjustArgvPointers(to);
	}
	
private:
	void adjustArgvPointers(ubyte[] to){
		// exploits fact that all argv pointers are intra-segment, so it
		// is enought to mod (mask) by the segment size and then add the
		// new segment base address

		foreach(ref str; argv){
			str = (cast(char*)(to.ptr + (cast(ulong)str.ptr & (to.length -1) )))[0..str.length];
		}

		argv = (cast(char[]*)(to.ptr + (cast(ulong)argv.ptr & (to.length -1) )))[0..argv.length];
	}

	public static:
	MessageInAbottle* getBottleForSegment(ubyte* seg){
		return cast(MessageInAbottle*)(seg + (oneGB - 4096)); 
	}

	MessageInAbottle* getMyBottle(){
		return getBottleForSegment(cast(ubyte*) oneGB);
	}
}

template populateChild(T){
	void populateChild(T argv, AddressSpace child, ubyte[] f, ubyte* stdin = null, ubyte* stdout = null){
		// XXX: restrict T to char[] and char[][]

		// map executable to default (kernel hardcoded) location in the child address space
		ubyte* dest = cast(ubyte*)oneGB;

		assert(child !is null && f !is null && dest !is null, "NULLS!!!!!\n");

		version(KERNEL){
			// kernel only executes init once, so its OK not to copy
		}else{
			ubyte* g = findFreeSegment(false).ptr;

			Syscall.create(g, oneGB, AccessMode.Writable|AccessMode.User|AccessMode.Executable);

			// XXX: instead of copying the whole thing we should only be duping the r/w data section 
			uint len = *(cast(ulong*)f.ptr) + ulong.sizeof;
			g[0..len] = f.ptr[0..len];

			f = g[0..f.length];
		}

		Syscall.map(child, f.ptr, dest, AccessMode.Writable|AccessMode.User|AccessMode.Executable);

		// bottle to bottle transfer of stdin/out isthe default case
		MessageInAbottle* bottle = MessageInAbottle.getMyBottle();
		MessageInAbottle* childBottle = MessageInAbottle.getBottleForSegment(f.ptr);
	
		// XXX: use findFreeSemgent to pick gib locations in child
		// assume default locations and non-TTY for redirected stdin/out
		childBottle.stdout = (cast(ubyte*)(2*oneGB))[0..oneGB];
		childBottle.stdoutIsTTY = false;
		childBottle.stdin = (cast(ubyte*)(3*oneGB))[0..oneGB];
		childBottle.stdinIsTTY = false;
		

		childBottle.setArgv(argv);
		
		// if no stdin/out is specified, us the same buffer as parent
		if(stdout is null){
			stdout = bottle.stdout.ptr;
			childBottle.stdoutIsTTY =	bottle.stdoutIsTTY;
		}

		if(stdin is null){
			stdin = bottle.stdin.ptr;
			childBottle.stdinIsTTY = bottle.stdinIsTTY;
		}

		// map stdin/out into child process
		Syscall.map(child, stdout, childBottle.stdout.ptr, AccessMode.Writable|AccessMode.User);
		Syscall.map(child, stdin, childBottle.stdin.ptr, AccessMode.Writable|AccessMode.User);
	}
}


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
											"address", 41,
											"available", 10,
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
												"address", 41,
												"available", 10,
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
			}
		}
	}
}

template PageLevel(ushort L){
	struct PageLevel{
		alias L level;

		static if(L == 1){
			PageTableEntry!("primary")[512] entries;

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
		}else{
			PageTableEntry!("secondary")[512] entries;

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

	walk!(isValidAddressHelper)(root, cast(ulong)vAddr, valid);

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
	
	walk!(modesForAddressHelper)(root, cast(ulong)vAddr, flags);

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

PhysicalAddress getPhysicalAddressOfSegment(ubyte* vAddr){
	PhysicalAddress physAddr = null;

	walk!(physicalAddressOfSegmentHelper)(root, cast(AddressFragment)vAddr, physAddr);

	return physAddr;
}

template physicalAddressOfSegmentHelper(T){
	bool physicalAddressOfSegmentHelper(T table, uint idx, ref PhysicalAddress physAddr){
		if(table.entries[idx].present){
			if(table.entries[idx].getMode() & (AccessMode.Segment|AccessMode.RootPageTable)){
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
		traverse!(preorderFindFreeSegmentHelper, noop)(root, startAddr, endAddr, vAddr, segmentParent);
		break;
	case 2:
		PageLevel!(2)* segmentParent;
		traverse!(preorderFindFreeSegmentHelper, noop)(root, startAddr, endAddr, vAddr, segmentParent);
		break;
	case 3:
		PageLevel!(3)* segmentParent;
		traverse!(preorderFindFreeSegmentHelper, noop)(root, startAddr, endAddr, vAddr, segmentParent);
		break;
	case 4:
		PageLevel!(4)* segmentParent;
		traverse!(preorderFindFreeSegmentHelper, noop)(root, startAddr, endAddr, vAddr, segmentParent);
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
template walk(alias U, T, S...){
	void walk(T table, ulong addr, ref S s){
		ulong idx;

		getNextIndex(addr, idx);

		if(U(table, idx, s)){

			static if(!(is (T == PageLevel!(1)*))){
				auto table2 = table.getTable(idx);
					
				walk!(U)(table2, addr, s);
			}
		}
	}
}

template traverse(alias PRE, alias POST, T, S...){
	bool traverse(T table, ulong startAddr, ulong endAddr, ref S s){
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
				directive = PRE(table, i, startIdx, endIdx, s);
			}

			static if(T.level != 1){
				if(directive == TraversalDirective.Descend){
					auto childTable = table.getTable(i);

					if(childTable !is null){
						bool stop = traverse!(PRE,POST)(childTable, frontAddr, backAddr, s);

						if(stop){
							return true;
						}
					}
				}else if(directive == TraversalDirective.Stop){
					return true;
				}
			}

			static if(!is(POST == noop)){
				POST(table, i, startIdx, endIdx, s);
			}
		}

		return false;
	}// end travesal()
}

// use this to skip pre or post traversal execution
template noop(K...){TraversalDirective noop(K k){return TraversalDirective.Descend;}}

enum TraversalDirective {
	Descend,
	Skip,
	Stop
}
