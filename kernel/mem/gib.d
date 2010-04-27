/*
 * gib.d
 *
 * This module provides the interface for a gib for the kernel.
 *
 */

module kernel.mem.gib;

import architecture.vm;

import kernel.core.kprintf;
import kernel.core.error;

import user.templates;

struct Metadata {
	ulong length;
}

struct Gib {

	ubyte* ptr() {
		return _start + Metadata.sizeof;
	}

	ubyte* pos() {
		return _curpos;
	}

	ubyte* address() {
		return _gibaddr;
	}

	ulong length() {
		// Grab length from metadata page
		return _metadata.length;
	}

	// Update length atomically
	// TODO: Atomic update
	void length(ulong val) {
		_metadata.length = val;
	}

	// Will move the pointer to the next page
	void seekAlign() {
		ulong pos = cast(ulong)_curpos;
		pos = pos & ~(cast(ulong)VirtualMemory.pagesize()-1);
		pos = pos + VirtualMemory.pagesize();
		_curpos = cast(ubyte*)pos;
	}

	// Will move the pointer by the specified amount.
	// Can be positive or negative.
	void seek(long amount) {
		_curpos += amount;
	}

	// Will move the pointer to the beginning of the region.
	void rewind() {
		_curpos = _start + Metadata.sizeof;
	}

	ErrorVal map(ubyte* start, ulong length) {
		return VirtualMemory.mapRegion(_curpos, start, length);
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

	// Close the gib
	ErrorVal close() {
		return ErrorVal.Fail;
	}

package:
	ubyte* _start;
	ubyte* _curpos;
	ubyte* _gibaddr;
	Metadata* _metadata;
}
