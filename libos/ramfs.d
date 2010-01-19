
module libos.ramfs;

private import user.syscall;

struct Gib {

	ubyte* ptr() {
		return _ptr;
	}

	ubyte* pos() {
		return _curptr;
	}

package:
	ubyte* _ptr;
	ubyte* _curptr;
}

class RamFS {
static:

	Gib open(char[] name, uint flags) {
		Gib ret;
		ret._ptr = user.syscall.open(name, flags);
		ret._curptr = ret._ptr;	
		return ret;
	}

	Gib create(char[] name, uint flags) {
		Gib ret;
		ret._ptr = user.syscall.create(name, flags);
		ret._curptr = ret._ptr;	
		return ret;
	}
}

