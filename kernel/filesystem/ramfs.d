
module kernel.filesystem.ramfs;

import kernel.system.info;
import kernel.core.error;
import kernel.mem.heap;

import kernel.core.kprintf;

import user.ramfs;

struct RamFS{
	static:
	public:
	
	void mapRegion(Inode* inode, void* addy, ulong length){
		//assert(length <= (directPtrs.length * 4096), "module too big to become a file");
		assert((cast(ulong)addy % 4096) == 0);
		
		uint i = 0;
		
		while((length > i*4096) && (i < inode.directPtrs.length)){
			inode.directPtrs[i] = cast(void*)(cast(ulong)addy + i*4096);
			i++;
		}
		
		if(length > i*4096){
			inode.indirectPtr = cast(IndirectPtrs*)Heap.allocPage();
			
			while((length > i*4096) && (i < inode.directPtrs.length + inode.indirectPtr.ptrs.length)){
				inode.indirectPtr.ptrs[i - inode.directPtrs.length] = cast(void*)(cast(ulong)addy + i*4096);
				i++;
			}
			
		}
		
	}

	DirPage* root;
	
	ErrorVal initialize(){
		root = cast(DirPage*)Heap.allocPage();
		
		for(uint i = 0; i < (System.numModules < NUM_DIR_ENTRIES ? System.numModules : NUM_DIR_ENTRIES); i++){
			root.entries[i].name = System.moduleInfo[i].name;
			
			kprintfln!("{}")(root.entries[i].name);
			
			root.entries[i].ptr.inode = cast(Inode*)Heap.allocPage();
			
			root.entries[i].ptr.inode.refcount = 1;
			root.entries[i].ptr.inode.length = System.moduleInfo[i].length;			

			root.entries[i].ptr.inode.isContiguous = true;

			mapRegion(root.entries[i].ptr.inode, System.moduleInfo[i].virtualStart,
																					System.moduleInfo[i].length);
			
		}
		
		return ErrorVal.Success;
	}
	
	Inode* open(char[] path){
		
		for(uint i = 0; (i < root.entries.sizeof) && (root.entries[i].name !is null); i++){
			if(root.entries[i].name == path && root.entries[i].isDir){
				return root.entries[i].ptr.inode;
			}
		}

		return null;
	}

}// end namespace foo