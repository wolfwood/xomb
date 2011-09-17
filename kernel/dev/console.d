// This implements a console (text-mode) VGA driver.

module kernel.dev.console;

// Import system info
import kernel.system.info;

// Errors
import kernel.core.error;
import kernel.core.kprintf;

// Shared structures for userspace
public import user.console;

import architecture.cpu;
import architecture.mutex;
import architecture.vm;


// This is the true interface to the console
class Console {
static:
public:
	// The number of columns and lines on the screen.
	const uint COLUMNS = 80;
	const uint LINES = 25;

	// The default color.
	const ubyte DEFAULTCOLORS = Color.LightGray;

	// The width of a tab
	const auto TABSTOP = 4;

	void switchToHigherHalfVirtualAddress() {
		videoMemoryLocation = System.kernel.virtualStart + cast(ulong)videoMemoryPhysLocation;
	}

	ubyte[] segment() {
		return _segment;
	}

	// This will init the console driver
	ErrorVal initialize() {
		info.width = COLUMNS;
		info.height = LINES;

		// metadata is in RAM page(s)
		uint ramSize = VirtualMemory.pagesize * (1+ MetaData.sizeof/VirtualMemory.pagesize);
		// memory mapped device size
		uint vramSize = 1024*1024;

		_segment = VirtualMemory.findFreeSegment(true, ramSize+vramSize);

		ubyte[] vid = VirtualMemory.createSegment(_segment, AccessMode.Writable|AccessMode.AllocOnAccess|AccessMode.Device);

		MetaData* videoMetaData = cast(MetaData*)vid.ptr;
		*videoMetaData = info;

		videoMetaData.videoBufferOffset = ramSize;

		videoMemoryLocation = vid.ptr + videoMetaData.videoBufferOffset;
		videoInfo = videoMetaData;

		VirtualMemory.mapRegion(videoMemoryLocation, videoMemoryPhysLocation, vramSize);

		uint temp = LINES * COLUMNS;
		temp++;

		Cpu.ioOut!(ushort, "0x3D4")(14);
		Cpu.ioOut!(ushort, "0x3D5")(temp >> 8);
		Cpu.ioOut!(ushort, "0x3D4")(15);
		Cpu.ioOut!(ushort, "0x3D5")(temp);

		return ErrorVal.Success;
	}

	// This method will clear the screen and return the cursor to (0,0).
	void clearScreen() {
		int i;

		for (i=0; i < COLUMNS * LINES * 2; i++) {
			*(videoMemoryLocation + i) = 0;
		}

		videoInfo.xpos = 0;
		videoInfo.ypos = 0;
	}

	long getGlobalY() {
		return videoInfo.globalY;
	}

	// This method will return the current location of the cursor
	void getPosition(out int x, out int y) {
		x = videoInfo.xpos;
		y = videoInfo.ypos;
	}

	// This method will set the current location of the cursor to the x and y given.
	synchronized void setPosition(int x, int y) {
		if (x < 0) { x = 0; }
		if (y < 0) { y = 0; }
		if (x >= COLUMNS) { x = COLUMNS - 1; }
		if (y >= LINES) { y = LINES - 1; }

		long difference = cast(long)y - cast(long)videoInfo.ypos;
		videoInfo.globalY += difference;

		videoInfo.xpos = x;
		videoInfo.ypos = y;
	}

	// This method will post the character to the screen at the current location.
	synchronized void putChar(char c) {
		_putChar(c);
	}

	// This mehtod will post a string to the screen at the current location.
	synchronized void putString(char[] s) {
		foreach(c; s) {
			_putChar(c);
		}
	}

	// This function sets the console colors back to their defaults.
	void resetColors() {
		videoInfo.colorAttribute = DEFAULTCOLORS;
	}

	// This function will set the text foreground to a new color.
	void setForeColor(Color newColor) {
		videoInfo.colorAttribute = (videoInfo.colorAttribute & 0xf0) | newColor;
	}

	// This function will set the text background to a new color.
	void setBackColor(Color newColor) {
		videoInfo.colorAttribute = (videoInfo.colorAttribute & 0x0f) | (newColor << 4);
	}

	// This function will set both the foreground and background colors.
	void setColors(Color foreColor, Color backColor) {
		videoInfo.colorAttribute = (foreColor & 0x0f) | (backColor << 4);
	}

	synchronized void scrollDisplay(uint numLines) {
		_scrollDisplay(numLines);
	}

	uint width() {
		return COLUMNS;
	}

	uint height() {
		return LINES;
	}

	void putCharUnsafe(char foo) {
		_putChar(foo);
	}

	void putStringUnsafe(char[] foo) {
		foreach(c; foo) {
			_putChar(c);
		}
	}

private:

	MetaData info;

	MetaData* videoInfo = &info;

	// Where the video memory lives (can be changed)
	ubyte* videoMemoryLocation = cast(ubyte*)videoMemoryPhysLocation;
	const PhysicalAddress videoMemoryPhysLocation = cast(PhysicalAddress)0xB8000UL;

	ubyte[] _segment;

	void _putChar(char c) {
		if (c == '\t') {
			// Insert a tab.
			videoInfo.xpos += TABSTOP;
		}
		else if (c != '\n' && c != '\r') {
			//videoInfo.xpos %= COLUMNS;
			//videoInfo.ypos %= LINES;
			ubyte* videoAddress = videoMemoryLocation;
			videoAddress += (videoInfo.xpos + (videoInfo.ypos * COLUMNS)) * 2;

			// Set the current piece of video memory to the character to print.
			*(videoAddress) = c & 0xFF;
			*(videoAddress + 1) = videoInfo.colorAttribute;

			// increase the cursor position
			videoInfo.xpos++;
		}

		// if you have reached the end of the line, or printing a newline, increase the y position
		if (c == '\n' || c == '\r' || videoInfo.xpos >= COLUMNS) {
			videoInfo.xpos = 0;
			videoInfo.ypos++;
			videoInfo.globalY++;

			if (videoInfo.ypos >= LINES) {
				_scrollDisplay(1);
			}
		}
	}


	// This function will scroll the entire screen.
	void _scrollDisplay(uint numLines) {
		// obviously, scrolling all lines results in a cleared display. Use the faster function.
		if (numLines >= LINES) {
			clearScreen();
			return;
		}

		int cury = 0;
		int offset1 = 0;
		int offset2 = numLines * COLUMNS;

		// Go through and shift the correct amount.
		for ( ; cury <= LINES - numLines; cury++) {
			for (int curx = 0; curx < COLUMNS; curx++) {
				*(videoMemoryLocation + (curx + offset1) * 2) = *(videoMemoryLocation + (curx + offset1 + offset2) * 2);
				*(videoMemoryLocation + (curx + offset1) * 2 + 1) = *(videoMemoryLocation + (curx + offset1 + offset2) * 2 + 1);
			}

			offset1 += COLUMNS;
		}

		// clear the remaining lines
		for (; cury <= LINES; cury++) {
			for (int curx = 0; curx < COLUMNS; curx++) {
				*(videoMemoryLocation + (curx + offset1) * 2) = 0x00;
				*(videoMemoryLocation + (curx + offset1) * 2 + 1) = 0x00;
			}
		}

		videoInfo.ypos -= numLines;

		if (videoInfo.ypos < 0) {
			videoInfo.ypos = 0;
		}
	}
}
