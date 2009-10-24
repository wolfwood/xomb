
module kernel.filesystem.ramfs;

import kernel.system.info;
import kernel.core.error;
import kernel.mem.heap;

import kernel.core.kprintf;

import architecture.vm;

import user.ramfs;

alias void* Gib;

int strcmp(char[] s1, char[] s2) {
	if (s1.length != s2.length) {
		return s1.length - s2.length;
	}

	foreach(uint i, ch; s1) {
		if (s2[i] != ch) {
			return s2[i] - ch;
		}
	}

	return 0;
}

bool streq(char[] s1, uint len, char[] s2) {
	if (len != s2.length) {
		return false;
	}

	foreach(uint i, ch; s2) {
		if (s1[i] != ch) {
			return false;
		}
	}

	return true;
}

bool streq(char[] s1, char[] s2) {
	if (s1.length != s2.length) {
		return false;
	}

	foreach(uint i, ch; s1) {
		if (s2[i] != ch) {
			return false;
		}
	}

	return true;
}

struct RamFS{
	static:
	public:

	Gib videoFile;
	Gib modules[System.moduleInfo.length];

	// WILKIE STUFF //
	Gib create(char[] filename) {
		Gib foo;
		kprintfln!("createFile: creating {}...")(filename);

		if (streq(filename, "/dev/video")) {
			kprintfln!("createFile: creating video file!!")();
			// it is video
			if (videoFile is null) {
				kprintfln!("createFile: creating video file.")();
				foo = VirtualMemory.allocGib();
				videoFile = foo;
			}
			else {
				foo = videoFile;
			}
		}
		else {
			// look up module, attach this module to this file
			for(uint i; i < System.numModules; i++) {
				uint len = System.moduleInfo[i].nameLength;
				kprintfln!("comparing {} {}")(System.moduleInfo[i].name[0..len], filename);
				if (streq(System.moduleInfo[i].name[0..len], filename)) {
					if (modules[i] is null) {
						kprintfln!("createFile: creating module file.")();
						modules[i] = foo;
					}
					else {
						foo = modules[i];
					}
					break;
				}
			}
		}
		*(cast(ulong*)foo) = 3;
		kprintfln!("Gib: {}")(foo);

		// return kernel address for file
		return foo;
	}

	void allocRegion(Gib file, ulong offset, ulong length) {
		// allocate pages and append them to the file region
	}

	void mapRegion(Gib file, void* addr, ulong offset, ulong length) {
		// map existing pages to the file region
	}

	Gib locate(char[] filename) {
		// locate the file from the path
		Gib ret;

		if (filename == "/dev/video") {
			ret = videoFile;
		}
		else {
			// locate module, return file address
			for(uint i; i < System.numModules; i++) {
				uint len = System.moduleInfo[i].nameLength;
				if (System.moduleInfo[i].name[0..len] == filename) {
					ret = modules[i];
					break;
				}
			}
		}

		return ret;
	}
		
	// OLD STUFF //
	
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
