module libos.fs.minfs;

public import user.environment;
import Syscall = user.syscall;

import libos.console;


alias ubyte[] File;

class MinFS{
	static:
	// open the SuperSegment, allowing metadata reads and writes
	void initialize(){
		Syscall.create(createAddr(0,0,0,257), oneGB, AccessMode.Writable | AccessMode.Global);
		
		hdr = cast(Header*)createAddr(0,0,0,257);
	}
	
	// this creates the 'SuperSegment', the super-block-like known-location which also happens to contain all the fs metadata (filenames)
	void format(){
		Syscall.create(createAddr(0,0,0,257), oneGB, AccessMode.Writable | AccessMode.Global);
		
		hdr = cast(Header*)createAddr(0,0,0,257);
		
		hdr.entries = (cast(char[]*)createAddr(0,0,0,257))[Header.sizeof .. Header.sizeof];
		hdr.strTable = (cast(char*)createAddr(0,1,0,257))[0..0];
	}
	
	// maps a segment's page tables (currently mapped in at a lower level in the tree under the global segment) into the root page tabel at a known location
	File open(char[] name, AccessMode mode, bool createFlag = false){
		File f = find(name);

		if((f is null) && createFlag){
			f = alloc(name);

			//ubyte[]
			Syscall.create(f.ptr, f.length, mode | AccessMode.Global);
		}else{
			//XXX: don't use create as open
			Syscall.create(f.ptr, f.length, mode | AccessMode.Global);
		}

		return f;
	}

	char[] findPrefix(char[] name, ref uint idx){
    char[] val = null;

		for(uint i = idx; i < hdr.entries.length; i++){
			char[] str = hdr.entries[i];
			// to check prefix we just do a normal string equals against the prefix-sized substring
			if(name.length <= str.length && name == str[0..name.length]){
				val = str;
				idx = i+1;
				break;
			}
		}
		
		return val;
	}


	// currently a non-refcounted hardlink... this FS is gonna need a garbage collector
	File link(char[] filename, char[] linkname){
		File file = find(filename), link = find(linkname);

		if(link is null){
			link = alloc(linkname);
		}else{
			return null;
		}

		// Global bit means this operates on the global segment table that is mapped in to all AddressSpaces. this also means we leave the AS as null
		Syscall.map(null, file.ptr, link.ptr, AccessMode.Read | AccessMode.Global);

		return link;
	}

private:

	struct Header{
		char[][] entries;
		char[] strTable;
	}
	
	Header* hdr;

	File find(char[] name){
		foreach(i, str; hdr.entries){
			if(name == str){
				return (cast(ubyte*)(cast(ulong)hdr + ((i+1) * oneGB)))[0..oneGB];
			}
		}
		
		return null;
	}
	
	File alloc(char[] name){
		char[][] entries = hdr.entries;
		char[][] entries2 = entries.ptr[0..(entries.length+1)];
		
		// XXX: lockfree
		hdr.entries = entries2;
		
		char[] strTable = hdr.strTable;

		char[] strTable2 = (strTable.ptr - name.length)[0..0];
		
		// XXX: lockfree
		hdr.strTable = strTable2;
		
		entries2[$-1] = strTable2.ptr[0..name.length];
		
		entries2[$-1][] = name[];
		
		return (cast(ubyte*)(cast(ulong)hdr + (entries2.length * oneGB)))[0..oneGB];
	}
	
	/*
		File grow(File f, uint bytes){
		
		}*/
	
	// XXX: these helpers should be defined elsewhere
	ubyte* createAddr(ulong indexLevel1,
											 ulong indexLevel2,
											 ulong indexLevel3,
											 ulong indexLevel4) {
		return cast(ubyte*) createAddress(indexLevel1, indexLevel2, indexLevel3, indexLevel4);
	}
}
