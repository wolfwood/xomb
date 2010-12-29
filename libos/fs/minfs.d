module libos.fs.minfs;

public import user.environment;
import Syscall = user.syscall;

import libos.console;


alias ubyte[] File;

class MinFS{
	static:
	void initialize(){
		Syscall.create(createAddr(0,0,0,257), oneGB, AccessMode.Writable | AccessMode.Global);
		
		hdr = cast(Header*)createAddr(0,0,0,257);
	}
	
	void format(){
		Syscall.create(createAddr(0,0,0,257), oneGB, AccessMode.Writable | AccessMode.Global);
		
		hdr = cast(Header*)createAddr(0,0,0,257);
		
		hdr.entries = (cast(char[]*)createAddr(0,0,0,257))[Header.sizeof .. Header.sizeof];
		hdr.strTable = (cast(char*)createAddr(0,1,0,257))[0..0];
	}
	
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
}
