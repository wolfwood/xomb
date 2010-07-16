
module libos.ramfs;

import user.templates;

import Syscall = user.syscall;
import libos.console;

// The beef of the logic involves this structure
// Add to directory structure
// Just use a linked list allocation

// The first item in the directory is the Directory.Header
// Followed by a linked list of Directory.Entry objects

struct DirectoryEntry {
	char[] name;
	uint flags;
}

struct Directory {
	ubyte* ptr() {
		return gib.ptr;
	}

	void close() {
		gib.close();
	}

	bool link(ref Gib foo, char[] name) {
		Directory.Header* header;
		header = cast(Directory.Header*)gib.ptr; 

		Directory.Entry* newEntry;

		char* nameptr;

		// Add after tail (if exists)
		if (header.tailOffset == 0) {
			// Empty Directory
			// Go to the first spot
			newEntry = cast(Directory.Entry*)(header + 1);
		}
		else {
			// Go to next spot
			Directory.Entry* entry = cast(Directory.Entry*)(gib.ptr + header.tailOffset);
			newEntry = cast(Directory.Entry*)(cast(ulong)(entry + 1) + entry.length);
		}

		newEntry.length = name.length;
		newEntry.ptr = foo.ptr;

		nameptr = cast(char*)(newEntry + 1);
		foreach (c; name) {
			*nameptr = c;
			nameptr++;
		}	

		if (header.tailOffset == 0) {
			// Place in directory
			header.headOffset = cast(ulong)newEntry - cast(ulong)gib.ptr;
			header.tailOffset = header.headOffset;
		}
		else {
			Directory.Entry* entry = cast(Directory.Entry*)(gib.ptr + header.tailOffset);
			header.tailOffset += Directory.Entry.sizeof + entry.length;
		}
		return true;
	}

	static Directory open(char[] name) {
		Directory ret;
		ret.gib = RamFS.open(name, 0);
		return ret;
	}

	int opApply(int delegate(ref DirectoryEntry foo) loopFunc) {
		DirectoryEntry dirent;
		Directory.Entry* current;
		Directory.Entry* tail;
		Directory.Header* header;
		char* nameptr;

		header = cast(Directory.Header*)gib.ptr;
		current = cast(Directory.Entry*)(gib.ptr + header.headOffset);
		tail = cast(Directory.Entry*)(gib.ptr + header.tailOffset);
		if (header.headOffset == 0) {
			// Directory is empty
			return 0;
		}

		for(;;) {
			nameptr = cast(char*)current + Directory.Entry.sizeof;
			if (current.length > 128) {
				current.length = 128;
			}
			dirent.name = nameptr[0..current.length];
			dirent.flags = current.flags;

			if (loopFunc(dirent) == 1) {
				return 1;
			}

			if (current is tail) {
				break;	
			}

			current = cast(Directory.Entry*)(nameptr + current.length + current.linklen);
		}


		return 0;
	}

	int opApply(int delegate(ref char[] foo) loopFunc) {
		DirectoryEntry dirent;
		Directory.Entry* current;
		Directory.Entry* tail;
		Directory.Header* header;
		char* nameptr;

		header = cast(Directory.Header*)gib.ptr;
		current = cast(Directory.Entry*)(gib.ptr + header.headOffset);
		tail = cast(Directory.Entry*)(gib.ptr + header.tailOffset);
		if (header.headOffset == 0) {
			// Directory is empty
			return 0;
		}

		for(;;) {
			nameptr = cast(char*)current + Directory.Entry.sizeof;
			if (current.length > 128) {
				current.length = 128;
			}
			dirent.name = nameptr[0..current.length];

			if (loopFunc(dirent.name) == 1) {
				return 1;
			}

			if (current is tail) {
				break;	
			}

			current = cast(Directory.Entry*)(nameptr + current.length + current.linklen);
		}


		return 0;
	}

	Directory.Entry* locate(char[] name) {
		Directory.Entry* current;
		Directory.Entry* tail;
		Directory.Header* header;
		char* nameptr;

		header = cast(Directory.Header*)gib.ptr;
		current = cast(Directory.Entry*)(gib.ptr + header.headOffset);
		tail = cast(Directory.Entry*)(gib.ptr + header.tailOffset);
		if (header.headOffset == 0) {
			// Directory is empty
			return null;
		}

		bool found = false;
		while(!found) {
			nameptr = cast(char*)current + Directory.Entry.sizeof;
			if (current.length > 128) {
				current.length = 128;
			}
			char[] curname = nameptr[0..current.length];

			if (name.length == curname.length) {
				bool nameEq = true;
				foreach(size_t i, c; name) {
					if (c != curname[i]) {
						nameEq = false;
						break;
					}
				}
				if (nameEq) {
					return current;
				}
			}

			// Compare curname

			if (current is tail) {
				// found remains false
				break;	
			}

			current = cast(Directory.Entry*)(nameptr + current.length + current.linklen);
		}

		return null;
	}

package:
	Gib gib;

	struct Header {
		uint headOffset;
		uint tailOffset;
	}

	struct Entry {
		ushort length;
		ushort linklen;
		uint flags;
		ubyte* ptr;
	}

	enum Mode {
		ReadOnly = 1,
		Directory = 2,
		Softlink = 4,
		Executable = 8,
	}
}

struct Metadata {
	ulong length;
}

struct Gib {

	ubyte* ptr() {
		return _start;
	}

	ubyte* pos() {
		return _curpos;
	}

	void seek(long amount) {
		_curpos += amount;
	}

	void rewind() {
		_curpos = _start;
	}

	ulong length() {
		return _metadata.length;
	}

	void close() {
	}

	// Will read from the current position the data requested.
	template read(T) {
		uint read(out T buffer) {
			size_t length;

			static if (IsArray!(T)) {
				length = buffer.length * ArrayType!(T).sizeof;
				foreach(ref ArrayType!(T) b; buffer) {
					ArrayType!(T)* ptr = cast(ArrayType!(T)*)_curpos;
					b = *ptr;
					_curpos += ArrayType!(T).sizeof;
				}
			}
			else {
				length = T.sizeof;
				T* ptr = cast(T*)_curpos;
				buffer = *ptr;
				_curpos += length;
			}

			return length;
		}
	}

	// Will write to the current position the data requested.
	template write(T) {
		uint write(T buffer) {
			size_t length;

			static if (IsArray!(T)) {
				length = buffer.length * ArrayType!(T).sizeof;
				foreach(ArrayType!(T) b; buffer) {					
					ArrayType!(T)* ptr = cast(ArrayType!(T)*)_curpos;
					*ptr = b;
					_curpos += ArrayType!(T).sizeof;
				}
			}
			else {
				length = T.sizeof;
				T* ptr = cast(T*)_curpos;
				*ptr = buffer;
				_curpos += length;
			}

			return length;
		}
	}

	ubyte opIndex(size_t i1) {
		return _start[i1];
	}

	size_t opIndexAssign(ubyte value, size_t i1) {
		_start[i1] = value;
		return i1;
	}

package:
	ubyte* _start;
	ubyte* _curpos;
	Metadata* _metadata;
}

class RamFS {
static:

	Gib open(char[] name, uint flags) {
		/*Gib ret;
		ret._start = Syscall.open(name, flags, nextGibIndex);
		nextGibIndex++;
		ret.rewind();
		ret._metadata = cast(Metadata*)(ret._start - Metadata.sizeof);
		return ret;*/
		Gib ret;
		return ret;
	}

	Gib create(char[] name, uint flags) {
		/*Gib ret;
		ret._start = Syscall.create(name, flags, nextGibIndex);
		nextGibIndex++;
		ret.rewind();
		ret._metadata = cast(Metadata*)(ret._start - Metadata.sizeof);
		return ret;*/
		Gib ret;
		return ret;
	}

	bool link(char[] name, char[] linkpath, uint flags) {
		return false;
//		return Syscall.link(name, linkpath, flags);
	}

private:
	uint nextGibIndex = 5;
}

