module kernel.dev.keyboard;

// Import the architecture specific keyboard driver
import architecture.keyboard;
import architecture.vm;

import kernel.core.error;

import kernel.config;

import user.keycodes;

import kernel.dev.console;

import kernel.filesystem.ramfs;
import kernel.mem.giballocator;
import kernel.mem.gib;

class Keyboard {
static:

	ErrorVal initialize() {
		_buffer = RamFS.create("/devices/keyboard", Access.Kernel | Access.Read | Access.Write);
		_writeOffset = cast(ushort*)_buffer.ptr;
		*_writeOffset = 0;
		_buffer.seek(2);
		_readOffset = cast(ushort*)_buffer.pos;
		*_readOffset = 0;
		_buffer.seek(2);
		_buffer.write(cast(ushort)(3 * VirtualMemory.pagesize()));
		_maxOffset = ((3 * VirtualMemory.pagesize()) / 2) - 3;
		ErrorVal ret = KeyboardImplementation.initialize(&putKey);
		return ret;
	}

private:

	void putKey(Key nextKey, bool released) {
		if (released) {
			nextKey = -nextKey;
		}

		if ((((*_writeOffset)+1) == *_readOffset) || ((*_writeOffset + 1) >= _maxOffset && (*_readOffset == 0))) {
			// lose this key
			return;
		}

		// put in the buffer at the write pointer position
		_buffer.write(cast(short)nextKey);
		if ((*_writeOffset + 1) >= _maxOffset) {
			_buffer.rewind();
			_buffer.seek(6);
			*_writeOffset = 0;
		}
		else {
			*_writeOffset = (*_writeOffset) + 1;
		}
	}

	Gib _buffer;
	ushort* _writeOffset;
	ushort* _readOffset;
	ushort _maxOffset;
}
