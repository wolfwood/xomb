module kernel.dev.keyboard;

// Import the architecture specific keyboard driver
import architecture.keyboard;
import architecture.vm;

import kernel.core.error;

import kernel.config;

import user.keycodes;


class Keyboard {
	static:

	ErrorVal initialize() {
		segment = VirtualMemory.findFreeSegment(true, BUFFER_SIZE);

		_buffer = cast(short[])VirtualMemory.createSegment(segment, AccessMode.DefaultKernel);

		// allocs
		_buffer[fourKB/ushort.sizeof] = 0;
		_buffer[2*fourKB/ushort.sizeof] = 0;

		_writeOffset = cast(ushort*)_buffer.ptr;
		*_writeOffset = 0;
		_readOffset = &((cast(ushort*)_buffer)[1]);
		*_readOffset = 0;

		((cast(ushort*)_buffer)[2]) = cast(ushort)BUFFER_SIZE;
		_maxOffset = (BUFFER_SIZE / ushort.sizeof) - 3;

		_buffer = _buffer[3..	_maxOffset];
		ErrorVal ret = KeyboardImplementation.initialize(&putKey);
		return ret;
	}

	ubyte[] segment;
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
		_buffer[*_writeOffset] = cast(short)nextKey;
		if ((*_writeOffset + 1) >= _maxOffset) {
			*_writeOffset = 0;
		}
		else {
			*_writeOffset = (*_writeOffset) + 1;
		}
	}

	short[] _buffer;
	ushort* _writeOffset;
	ushort* _readOffset;
	ushort _maxOffset;

	const uint BUFFER_SIZE = 3 * VirtualMemory.pagesize();
}