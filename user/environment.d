module user.environment;

import user.util;
import user.syscall;

version(KERNEL){
	import kernel.mem.pageallocator;
}

typedef ubyte* AddressSpace;

const ulong oneGB = 1024*1024*1024UL;
//const ubyte[] squareGB = (cast(ubyte*)oneGB)[0..oneGB];

enum AccessMode : uint {
	Read = 0,

		// bits that get encoded in the available bits
		Global = 1,
		AllocOnAccess = 2,
	 
		// bits that are encoded in hardware defined PTE bits
		Writable = 4,
		Kernel = 8,

		// Default policies
		DefaultUser = Writable,
		DefaultKernel = Writable | AllocOnAccess | Kernel
}


// place to store values that must be communicated to the  child process from the parent
struct MessageInAbottle {
	ubyte[] stdin;
	ubyte[] stdout;
	bool stdinIsTTY, stdoutIsTTY;
	char[][] argv;

	// assumes alloc on write beyond end of exe
	void setArgv(char[][] parentArgv, ubyte[] to = (cast(ubyte*)oneGB)[0..oneGB]){
		// assumes allocation on write region exists immediately following bottle

		// allocate argv's array reference array first, since we know how long it is
		argv = (cast(char[]*)this + MessageInAbottle.sizeof)[0..parentArgv.length];
		
		// this will be a sliding window for the strngs themselves, allocated after the argv array reference array 
		char[] storage = (cast(char*)argv[length..length].ptr)[0..0];

		foreach(i, str; parentArgv){
			storage = storage[length..length].ptr[0..str.length];

			storage[] = str[];

			argv[i] = storage;
		}

		// adjust pointers
		adjustArgvPointers(to);
	}
	
	void setArgv(char[] parentArgv,  ubyte[] to = (cast(ubyte*)oneGB)[0..oneGB]){

		// allocate strings first, since we know how long they are
		char[] storage = (cast(char*)this + MessageInAbottle.sizeof)[0..parentArgv.length];
		
		storage[] = parentArgv[];
		
		// determine length of array reference array
		int substrings = 1;

		foreach(ch; storage){
			if(ch == ' '){
				substrings++;
			}
		}
		
		// allocate array reference array
		argv = (cast(char[]*)storage[length..length].ptr)[0..substrings];

		char* arg = storage.ptr;
		int len, i;

		foreach(ch; storage){
			if(ch == ' '){
				argv[i] = arg[0..len];
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
		return cast(MessageInAbottle*)seg + *cast(ulong*)seg;
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
		map(child, f.ptr, dest, AccessMode.Writable);

		// bottle to bottle transfer of stdin/out isthe default case
		MessageInAbottle* bottle = MessageInAbottle.getMyBottle();
		MessageInAbottle* childBottle = MessageInAbottle.getBottleForSegment(f.ptr);
	
		// XXX: use findFreeSemgent to pick gib locations in child
		// assume default locations and non-TTY for rebound stdin/out
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
		map(child, stdout, childBottle.stdout.ptr, AccessMode.Writable);
		map(child, stdin, childBottle.stdin.ptr, AccessMode.Read);
	}
}

// find free gib magic
// XXX: handle global and different sizes!
template findFreeSegment(bool upperhalf = true, bool global = false, uint size = 1024*1024*1024){
	ubyte* findFreeSegment(){
		const uint dividingLine = 256;
		static uint last1 = (upperhalf ? dividingLine : 0), last2 = (upperhalf ? 0 : 1);
			
		bool foundFree;
		void* addy;

		while(!foundFree){
			PageLevel3* pl3 = root.getTable(last1);

			if(pl3 is null){
				addy = createAddress(0, 0, ((!upperhalf && (last1== 0))? 1 : 0), last1);
				last2 = 1;
				break;
			}

			while(!foundFree && (last2 < pl3.entries.length)){
				if(pl3.entries[last2].pml == 0){
					foundFree = true;
					addy = createAddress(0, 0, last2, last1);
				}
				last2++;
			}

			if(last2 >= pl3.entries.length){
				last1++;
				last2 = 0;
			}

			if(upperhalf){
				if(last1 >= root.entries.length){
					last1 = dividingLine;
				}
			}else{
				if(last1 >= dividingLine){
					last1 = 0;
					last2 = 1;
				}

			}

		}
			
		assert(addy !is null, "null gib find fail\n");

		return cast(ubyte*)addy;
	}
}


// -- Paging Structures -- //

// The x86 implements a four level page table.
// We use the 4KB page size hierarchy

// The levels are defined here, many are the same but they need
// to be able to be typed differently so we don't make a stupid
// mistake.



struct SecondaryField {

	ulong pml;

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

	ubyte* location() {
		return cast(ubyte*)(cast(ulong)address() << 12);
	}
}
	
struct PrimaryField {

	ulong pml;

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

	ubyte* location() {
		return cast(ubyte*)(cast(ulong)address() << 12);
	}
}

struct PageLevel4 {
	SecondaryField[512] entries;

	PageLevel3* getTable(uint idx) {
		if (entries[idx].present == 0) {
			return null;
		}
			
		// Calculate virtual address
		return cast(PageLevel3*)(0xFFFFFF7F_BFE00000 + (idx << 12));
	}

	version(KERNEL){
		void setTable(uint idx, ubyte* address, bool usermode = false) {
			entries[idx].pml = cast(ulong)address;
			entries[idx].present = 1;
			entries[idx].rw = 1;
			entries[idx].us = usermode;
		}

		PageLevel3* getOrCreateTable(uint idx, bool usermode = false) {
			PageLevel3* ret = getTable(idx);
			
			if (ret is null) {
				// Create Table
				ret = cast(PageLevel3*)PageAllocator.allocPage();

				// Set table entry
				entries[idx].pml = cast(ulong)ret;
				entries[idx].present = 1;
				entries[idx].rw = 1;
				entries[idx].us = usermode;
				
				// Calculate virtual address
				ret = cast(PageLevel3*)(0xFFFFFF7F_BFE00000 + (idx << 12));
				
				*ret = PageLevel3.init;
			}
			
			return ret;
		}
	}
}

struct PageLevel3 {
	SecondaryField[512] entries;

	PageLevel2* getTable(uint idx) {
		if (entries[idx].present == 0) {
			return null;
		}

		ulong baseAddr = cast(ulong)this;
		baseAddr &= 0x1FF000;
		baseAddr >>= 3;
		return cast(PageLevel2*)(0xFFFFFF7F_C0000000 + ((baseAddr + idx) << 12));
	}

	version(KERNEL){
		void setTable(uint idx, ubyte* address, bool usermode = false) {
			entries[idx].pml = cast(ulong)address;
			entries[idx].present = 1;
			entries[idx].rw = 1;
			entries[idx].us = usermode;
		}
		
		PageLevel2* getOrCreateTable(uint idx, bool usermode = false) {
			PageLevel2* ret = getTable(idx);
			
			if (ret is null) {
				// Create Table
				ret = cast(PageLevel2*)PageAllocator.allocPage();
				
				// Set table entry
				entries[idx].pml = cast(ulong)ret;
				entries[idx].present = 1;
				entries[idx].rw = 1;
				entries[idx].us = usermode;
				
				// Calculate virtual address
				ulong baseAddr = cast(ulong)this;
				baseAddr &= 0x1FF000;
				baseAddr >>= 3;
				ret = cast(PageLevel2*)(0xFFFFFF7F_C0000000 + ((baseAddr + idx) << 12));
				
				*ret = PageLevel2.init;
				//if (usermode) { kprintfln!("creating pl3 {}")(idx); }
			}

			return ret;
		}
	}
}
	
struct PageLevel2 {
	SecondaryField[512] entries;

	PageLevel1* getTable(uint idx) {
		//			kprintfln!("getting pl2 {}?")(idx);
		if (entries[idx].present == 0) {
			//				kprintfln!("no pl2 {}!")(idx);
			return null;
		}
		//			kprintfln!("getting pl2 {}!")(idx);

		ulong baseAddr = cast(ulong)this;
		baseAddr &= 0x3FFFF000;
		baseAddr >>= 3;
		return cast(PageLevel1*)(0xFFFFFF80_00000000 + ((baseAddr + idx) << 12));
	}

	version(KERNEL){
		void setTable(uint idx, ubyte* address, bool usermode = false) {
			entries[idx].pml = cast(ulong)address;
			entries[idx].present = 1;
			entries[idx].rw = 1;
			entries[idx].us = usermode;
		}
		
		PageLevel1* getOrCreateTable(uint idx, bool usermode = false) {
			PageLevel1* ret = getTable(idx);
			
			if (ret is null) {
				// Create Table
				//				if (usermode) { kprintfln!("creating pl2 {}?")(idx); }
				ret = cast(PageLevel1*)PageAllocator.allocPage();
				
				// Set table entry
				entries[idx].pml = cast(ulong)ret;
				entries[idx].present = 1;
				entries[idx].rw = 1;
				entries[idx].us = usermode;
				
				// Calculate virtual address
				ulong baseAddr = cast(ulong)this;
				baseAddr &= 0x3FFFF000;
				baseAddr >>= 3;
				ret = cast(PageLevel1*)(0xFFFFFF80_00000000 + ((baseAddr + idx) << 12));
				
				*ret = PageLevel1.init;
				//				if (usermode) { kprintfln!("creating pl2 {}")(idx); }
			}
			
			return ret;
		}
	}
}

struct PageLevel1 {
	PrimaryField[512] entries;

	void* physicalAddress(uint idx) {
		return cast(void*)(entries[idx].address << 12);
	}
}

void* createAddress(ulong indexLevel1, ulong indexLevel2,	ulong indexLevel3, ulong indexLevel4) {
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

	return cast(void*) vAddr;
}

const PageLevel4* root = cast(PageLevel4*)0xFFFFFFFF_FFFFF000;