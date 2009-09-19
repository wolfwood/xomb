module libos.libconsole;

import user.syscall;
import user.console;

struct Console {
static:

	enum Color : ubyte {
		Black			= 0x00,
		Blue			= 0x01,
		Green			= 0x02,
		Cyan			= 0x03,
		Red				= 0x04,
		Magenta			= 0x05,
		Yellow			= 0x06,
		LightGray		= 0x07,
		Gray			= 0x08,
		LightBlue		= 0x09,
		LightGreen		= 0x0A,
		LightCyan		= 0x0B,
		LightRed		= 0x0C,
		LightMagenta	= 0x0D,
		LightYellow		= 0x0E,
		White			= 0x0F
	}
	
	void initialize() {

		requestConsole(&cinfo);

		if (cinfo.buffer is null) {
			// boo
		}

		_xpos = 0;
		_ypos = 0;
	}

	void putChar(char c) {
		if (c == '\t') {
			_xpos += TABSTOP;
		}
		else if (c != '\n' && c != '\r') {
			ubyte* ptr = cast(ubyte*)cinfo.buffer;
			ptr += (_xpos + (_ypos * cinfo.width)) * 2;

			// Set the current piece of video memory to the character
			*(ptr) = c & 0xff;
			*(ptr + 1) = _attr;

			// Increment
			_xpos++;
		}

		// check for end of line, or newline
		if (c == '\n' || c == '\r' || _xpos >= cinfo.width) {
			_xpos = 0;
			_ypos++;

			while (_ypos >= cinfo.height) {
				scroll(1);
			}
		}
	}

	void putString(char[] string) {
		foreach(c; string) {
			putChar(c);
		}
	}

	void clear() {
		ubyte* ptr = cast(ubyte*)cinfo.buffer;

		for (int i; i < cinfo.width * cinfo.height * 2; i += 2) {
			*(ptr + i) = 0x00;
			*(ptr + i + 1) = _attr;
		}

		_xpos = 0;
		_ypos = 0;
	}

	void scroll(uint numLines) {
		ubyte* ptr = cast(ubyte*)cinfo.buffer;

		if (numLines >= cinfo.height) {
			clear();
			return;
		}

		int cury = 0;
		int offset1 = 0;
		int offset2 = numLines * cinfo.width;

		// Go through and shift the correct amount
		for ( ; cury <= cinfo.height - numLines; cury++) {
			for (int curx = 0; curx < cinfo.height; curx++) {
				*(ptr + (curx + offset1) * 2) 
					= *(ptr + (curx + offset1 + offset2) * 2);
				*(ptr + (curx + offset1) * 2 + 1) 
					= *(ptr + (curx + offset1 + offset2) * 2 + 1);
			}

			offset1 += cinfo.width;
		}

		// clear remaining lines
		for ( ; cury <= cinfo.height; cury++) {
			for (int curx = 0; curx < cinfo.width; curx++) {
				*(ptr + (curx + offset1) * 2) = 0x00;
				*(ptr + (curx + offset1) * 2 + 1) = 0x00;
			}
		}

		_ypos -= numLines;
		if (_ypos < 0) {
			_ypos = 0;
		}
	}

	void position(uint x, uint y) {
		_xpos = x;
		_ypos = y;

		if (_xpos >= cinfo.width) {
			_xpos = cinfo.width - 1;
		}

		if (_ypos >= cinfo.height) {
			_ypos = cinfo.height - 1;
		}
	}

	void reset() {
		_attr = DEFAULTCOLORS;
		clear();
	}

	void resetColor() {
		_attr = DEFAULTCOLORS;
	}

	void forecolor(Color clr) {
		_attr = (_attr & 0xf0) | clr; 
	}

	Color forecolor() {
		ubyte clr = _attr & 0xf;
		return cast(Color)clr;
	}

	void backcolor(Color clr) {
		_attr = (_attr & 0x0f) | (clr << 4);
	}

	Color backcolor() {
		ubyte clr = _attr & 0xf0;
		clr >>= 4;
		return cast(Color)clr;
	}

	uint width() {
		return cinfo.width;
	}

	uint height() {
		return cinfo.height;
	}

private:

	ConsoleInfo cinfo;

	int _ypos;
	int _xpos;

	ubyte _attr = DEFAULTCOLORS;

	const ubyte DEFAULTCOLORS = Color.LightGray;
	const ubyte TABSTOP = 4;
}
