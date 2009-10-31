
module user.ramfs;

alias void* Gib;










// BLEH
	
alias void* PagePtr;

struct Inode{
	uint refcount;
	bool isContiguous;
	bool[3] reserved;
	ulong length;

	PagePtr[507] directPtrs;
	IndirectPtrs* indirectPtr;
	DoubleIndirectPtrs* doubleIndirectPtr;
	TripleIndirectPtrs* tripleIndirectPtr;
}
	
struct IndirectPtrs{
	PagePtr[512] ptrs;
}


struct DoubleIndirectPtrs{
	IndirectPtrs*[512] ptrs;
}

struct TripleIndirectPtrs{
	DoubleIndirectPtrs*[512] ptrs;
}

struct DirEntry{
	char[] name;
	bool isDir;
	bool[3] reserved;


	union PtrUnion{
		Inode* inode;
		DirPage* dirpage;
	}  
	
	PtrUnion ptr;
}

const uint NUM_DIR_ENTRIES = 4096 / DirEntry.sizeof;

struct DirPage{
	DirEntry[NUM_DIR_ENTRIES] entries;
}

static assert(Inode.sizeof == 4096);
static assert(IndirectPtrs.sizeof == 4096);
static assert(DoubleIndirectPtrs.sizeof == 4096);
//static assert(DirEntry.sizeof == 32);
static assert(DirPage.sizeof == 4096);

