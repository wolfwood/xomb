module kernel.filesystem.ramfs;

import kernel.system.info;
import kernel.core.error;
import kernel.mem.heap;

import kernel.core.kprintf;

import kernel.environ.info;
import kernel.environ.scheduler;

import architecture.vm;

import kernel.mem.giballocator;
import kernel.mem.gib;

// The beef of the logic involves this structure
// Add to directory structure
// Just use a linked list allocation

// The first item in the directory is the Directory.Header
// Followed by a linked list of Directory.Entry objects

struct Directory {
	void alloc() {
		gib = GibAllocator.alloc(Access.Kernel | Access.Read | Access.Write);

		Directory.Header* header = cast(Directory.Header*)gib.ptr;
		header.headOffset = 0;
		header.tailOffset = 0;
	}

	ubyte* address() {
		return gib.address;
	}

	ErrorVal link(ref Gib foo, char[] name) {
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
		newEntry.ptr = foo.address;

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
		return ErrorVal.Success;
	}

	void open(Directory.Entry* entry, uint flags) {
		gib = GibAllocator.open(entry.ptr, flags);
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

			current = cast(Directory.Entry*)(nameptr + current.length);
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
		uint length;
		uint flags;
		ubyte* ptr;
	}
}

class RamFS {
static:

	ErrorVal initialize() {
		// Make root
		Directory sub;

		rootDir.alloc();

		sub.alloc();
		rootDir.link(sub.gib, "binaries");

		sub.alloc();
		rootDir.link(sub.gib, "configuration");

		sub.alloc();
		rootDir.link(sub.gib, "kernel");

		sub.alloc();
		rootDir.link(sub.gib, "libraries");

		sub.alloc();
		rootDir.link(sub.gib, "share");

		sub.alloc();
		rootDir.link(sub.gib, "system");

		sub.alloc();
		rootDir.link(sub.gib, "temp");

		sub.alloc();
		rootDir.link(sub.gib, "devices");

		return ErrorVal.Success;
	}

	// Mapping names to pagetables
	ubyte* locate(char[] path) {
		size_t pos = 0;
		Directory curDir = rootDir;

		ubyte* last;

		void innerLocate(size_t from, size_t to) {
			Directory.Entry* entry = curDir.locate(path[from..to]);
			curDir.open(entry, Access.Kernel | Access.Read | Access.Write);
			last = entry.ptr;
		}

		foreach(size_t i, c; path) {
			if (c == '/') {
				if (pos != i) {
					innerLocate(pos, i);
				}
				pos = i+1;
			}
		}
		if (pos < path.length) {
			innerLocate(pos, path.length);
		}
		return last;
	}

	ErrorVal mkdir(Gib curDir, char[] name) {
		Directory dir;
		dir.gib = curDir;

		Directory newDir;
		newDir.alloc();

		return dir.link(newDir.gib, name);
	}

	ErrorVal destroy() {
		return ErrorVal.Fail;
	}

	Gib create(char[] name, uint flags) {
		// Open directory where name should be placed
		char[] path;
		char[] filename;
		Gib newGib;
		if (splitPath(name, path, filename) == ErrorVal.Fail) {
			return newGib;
		}

		ubyte* dirptr = locate(path);
		Directory dir;
		dir.gib = GibAllocator.open(dirptr, Access.Kernel | Access.Read | Access.Write);

		newGib = GibAllocator.alloc(flags);
		dir.link(newGib, filename);

		return newGib;
	}

	Gib open(char[] name, uint flags) {
		// Open directory where name should be placed
		Gib gib;
		ubyte* gibptr = locate(name);
		if (gibptr !is null) {
			gib = GibAllocator.open(gibptr, flags);
		}
		return gib;
	}

	ErrorVal close() {
		return ErrorVal.Fail;
	}

	ErrorVal link() {
		return ErrorVal.Fail;
	}

private:

	ErrorVal splitPath(ref char[] fullpath, ref char[] path, ref char[] filename) {
		foreach_reverse(size_t i, c; fullpath) {
			if (c == '/') {
				if (i == fullpath.length - 1) {
					return ErrorVal.Fail;
				}
				path = fullpath[0..i];
				filename = fullpath[i+1..$];
				break;
			}
		}
		return ErrorVal.Success;
	}
	Directory rootDir;
}
