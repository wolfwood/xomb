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
// Just use a binded list allocation

// The first item in the directory is the Directory.Header
// Followed by a binded list of Directory.Entry objects

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

	// Create a soft link
	ErrorVal link(char[] name, char[] path, uint flags=0) {
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
			newEntry = cast(Directory.Entry*)(cast(ulong)(entry + 1) + entry.length + entry.linklen);
		}

		newEntry.length = name.length;
		newEntry.linklen = path.length;
		newEntry.ptr = null;
		newEntry.flags = flags | Mode.Softlink;

		nameptr = cast(char*)(newEntry + 1);
		foreach (c; name) {
			*nameptr = c;
			nameptr++;
		}	

		foreach (c; path) {
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
			header.tailOffset += Directory.Entry.sizeof + entry.length + entry.linklen;
		}
		return ErrorVal.Success;
	}

	// Create a hard link (unreferenced!)
	ErrorVal bind(ref Gib foo, char[] name, uint flags = 0) {
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
			newEntry = cast(Directory.Entry*)(cast(ulong)(entry + 1) + entry.length + entry.linklen);
		}

		newEntry.length = name.length;
		newEntry.linklen = 0;
		newEntry.ptr = foo.address;
		newEntry.flags = flags;

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
	}
}

class RamFS {
static:

	ErrorVal initialize() {
		// Make root
		Directory sub;

		rootDir.alloc();

		sub.alloc();
		rootDir.bind(sub.gib, "binaries", Directory.Mode.ReadOnly | Directory.Mode.Directory);

		sub.alloc();
		rootDir.bind(sub.gib, "configuration", Directory.Mode.ReadOnly | Directory.Mode.Directory);

		sub.alloc();
		rootDir.bind(sub.gib, "kernel", Directory.Mode.ReadOnly | Directory.Mode.Directory);

		sub.alloc();
		rootDir.bind(sub.gib, "libraries", Directory.Mode.ReadOnly | Directory.Mode.Directory);

		sub.alloc();
		rootDir.bind(sub.gib, "share", Directory.Mode.ReadOnly | Directory.Mode.Directory);

		sub.alloc();
		rootDir.bind(sub.gib, "system", Directory.Mode.ReadOnly | Directory.Mode.Directory);

		sub.alloc();
		rootDir.bind(sub.gib, "temp", Directory.Mode.ReadOnly | Directory.Mode.Directory);

		sub.alloc();
		rootDir.bind(sub.gib, "devices", Directory.Mode.ReadOnly | Directory.Mode.Directory);

		rootDir.link("fluff", "/devices");

		return ErrorVal.Success;
	}

	// Mapping names to pagetables
	ubyte* locate(char[] path) {
		size_t pos = 0;
		Directory curDir = rootDir;

		if (path.length == 1 && path[0] == '/') {
			// Root directory
			return rootDir.address();
		}

		ubyte* last;

		void innerLocate(size_t from, size_t to) {
			Directory.Entry* entry = curDir.locate(path[from..to]);
			curDir.open(entry, Access.Kernel | Access.Read | Access.Write);
			if (entry.linklen > 0) {
				// soft link

				// Expand out to the actual place
				// Get link path
				char* linkptr = cast(char*)(entry + 1);
				linkptr += entry.length;
				char[] linkpath = linkptr[0..entry.linklen];
			
				ubyte* gibptr = locate(linkpath);
				if (gibptr !is null) {
					curDir.gib = GibAllocator.open(gibptr, Access.Kernel | Access.Read | Access.Write);
				}
				last = gibptr;
			}
			else {
				last = entry.ptr;
			}
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

		return dir.bind(newDir.gib, name);
	}

	ErrorVal destroy() {
		return ErrorVal.Fail;
	}

	Gib create(char[] name, uint flags, uint gibIndex = 1) {
		// Open directory where name should be placed
		char[] path;
		char[] filename;
		Gib newGib;
		if (splitPath(name, path, filename) == ErrorVal.Fail) {
			return newGib;
		}

		ubyte* dirptr = locate(path);
		Directory dir;
		dir.gib = GibAllocator.open(dirptr, Access.Kernel | Access.Read | Access.Write, gibIndex);

		newGib = GibAllocator.alloc(flags);
		dir.bind(newGib, filename);

		return newGib;
	}

	Gib open(char[] name, uint flags, uint gibIndex = 1) {
		// Open directory where name should be placed
		Gib gib;
		ubyte* gibptr = locate(name);
		if (gibptr !is null) {
			gib = GibAllocator.open(gibptr, flags, gibIndex);
		}
		return gib;
	}

	ErrorVal close() {
		return ErrorVal.Fail;
	}

	ErrorVal link(char[] name, char[] linkpath, int flags = 0) {
		// Open directory where name should be placed
		char[] path;
		char[] filename;
		Gib newGib;
		if (splitPath(name, path, filename) == ErrorVal.Fail) {
			return ErrorVal.Fail;
		}

		ubyte* dirptr = locate(path);
		Directory dir;
		dir.gib = GibAllocator.open(dirptr, Access.Kernel | Access.Read | Access.Write);

		dir.link(filename, linkpath, flags);
		return ErrorVal.Success;
	}

	ErrorVal bind() {
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
