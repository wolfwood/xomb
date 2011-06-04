module libos.fs.minfs;

public import user.environment;
import Syscall = user.syscall;

import libos.console;

alias ubyte[] File;


/*
	Overview:

	In this filesystem the managed objects are contiguous ranges of
	virtual memory. The convention currently used is that allocation is
	sparse and on demand.  The virtual size allocated to an object is
	1GB, and convention is that files based on these objects track
	size-in-bytes and pointers to extension blocks, internally, this
	code does not depend on this behavior, however.  The only metadata
	stored is an identifying string.  This metadata is organized in a
	single 1GB super-segment, at the known location returned by
	createAddr(0,0,0,257).  The header, which occupies a fixed number of
	the initial bytes of the super-segment, points to two arrays. The
	first, growing out from the header, is the entries array.  This
	array serves both as an object allocation table, and, if the entry
	is non-null, points to the name used to identify the object, if any.
	The names are allocated in a string table which grows down from the
	highest bytes of the segment.
 */


class MinFS{
	static:
	// open the SuperSegment, allowing metadata reads and writes
	void initialize(){
		Syscall.create(createAddr(0,0,0,257), oneGB, AccessMode.User|AccessMode.Writable|AccessMode.Global|AccessMode.AllocOnAccess);
		
		hdr = cast(Header*)createAddr(0,0,0,257);
	}
	
	// this creates the 'SuperSegment', the super-block-like known-location which also happens to contain all the fs metadata (filenames)
	void format(){
		Syscall.create(createAddr(0,0,0,257), oneGB, AccessMode.User|AccessMode.Writable|AccessMode.Global|AccessMode.AllocOnAccess);
		
		hdr = cast(Header*)createAddr(0,0,0,257);
		
		hdr.entries = (cast(char[]*)createAddr(0,0,0,257))[Header.sizeof .. Header.sizeof];
		hdr.strTable = (cast(char*)createAddr(0,1,0,257))[0..0];
	}
	
	// maps a segment's page tables (currently mapped in at a lower level in the tree under the global segment) into the root page tabel at a known location
	File open(char[] name, AccessMode mode, bool createFlag = false){
		File f = find(name);

		mode |= AccessMode.User;

		if((f is null) && createFlag){
			f = alloc(name);

			if(mode & AccessMode.Writable){
				mode |= AccessMode.AllocOnAccess;
			}

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

		// XXX: limit permessions to those that are allowed on the taget of the link

		// Global bit means this operates on the global segment table that is mapped in to all AddressSpaces. this also means we leave the AS as null
		Syscall.map(null, file.ptr, link.ptr, AccessMode.Writable|AccessMode.AllocOnAccess|AccessMode.Global);

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
