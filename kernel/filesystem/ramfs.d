
module kernel.filesystem.ramfs;

import kernel.system.info;
import kernel.core.error;
import kernel.mem.heap;

import kernel.core.kprintf;

struct RamFS{
	static:
	public:
	
	alias void* PagePtr;
	
	struct Inode{
		uint refcount;
		uint reserved;
		PagePtr[508] directPtrs;
		IndirectPtrs* indirectPtr;
		DoubleIndirectPtrs* doubleIndirectPtr;
		TripleIndirectPtrs* tripleIndirectPtr;

		void mapRegion(void* addy, ulong length){
			//assert(length <= (directPtrs.length * 4096), "module too big to become a file");
			assert((cast(ulong)addy % 4096) == 0);

			uint i = 0;

			while((length > i*4096) && (i < directPtrs.length)){
				directPtrs[i] = cast(void*)(cast(ulong)addy + i*4096);
				i++;
			}

			if(length > i*4096){
				indirectPtr = cast(IndirectPtrs*)Heap.allocPage();

				while((length > i*4096) && (i < directPtrs.length + indirectPtr.ptrs.length)){
					indirectPtr.ptrs[i - directPtrs.length] = cast(void*)(cast(ulong)addy + i*4096);
					i++;
				}
				
			}
			
		}
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
		char[119] name;
		bool isDir;
		
		union PtrUnion{
			Inode* inode;
			DirPage* dirpage;
		}
		
		PtrUnion ptr;
	}

	const uint NUM_DIR_ENTRIES = 32;
	
	struct DirPage{
		DirEntry[NUM_DIR_ENTRIES] entries;
	}
	
	static assert(Inode.sizeof == 4096);
	static assert(IndirectPtrs.sizeof == 4096);
	static assert(DoubleIndirectPtrs.sizeof == 4096);
	static assert(DirEntry.sizeof == 128);
	static assert(DirPage.sizeof == 4096);
	
	DirPage* root;

	ErrorVal initialize(){
		root = cast(DirPage*)Heap.allocPage();
		
		for(uint i = 0; i < (System.numModules < NUM_DIR_ENTRIES ? System.numModules : NUM_DIR_ENTRIES); i++){
			root.entries[i].name[0..System.moduleInfo[i].name.length] = System.moduleInfo[i].name[0..$];
			
			kprintfln!("{}")(root.entries[i].name);

			root.entries[i].ptr.inode = cast(Inode*)Heap.allocPage();
			
			root.entries[i].ptr.inode.refcount = 1;

			root.entries[i].ptr.inode.mapRegion(System.moduleInfo[i].virtualStart,
																					System.moduleInfo[i].length);
			
		}

		return ErrorVal.Success;
	}

}// end namespace foo