
module libos.ramfs;

import user.templates;

private import user.syscall;

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
}

class RamFS {
static:

	Gib open(char[] name, uint flags) {
		Gib ret;
		ret._start = user.syscall.open(name, flags, nextGibIndex);
		nextGibIndex++;
		ret._curpos = ret._start;
		return ret;
	}

	Gib create(char[] name, uint flags) {
		Gib ret;
		ret._start = user.syscall.create(name, flags, nextGibIndex);
		nextGibIndex++;
		ret._curpos = ret._start;
		return ret;
	}

private:
	uint nextGibIndex = 1;
}

