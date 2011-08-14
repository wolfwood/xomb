module libos.console;

import user.console;


struct Console {
static:

	// The default color.
	const ubyte DEFAULTCOLORS = Color.LightGray;

	// The width of a tab
	const auto TABSTOP = 4;

	void initialize(ubyte* vidgib) {

		//video = RamFS.open("/devices/video", 0);

		videoBuffer = vidgib;

		// Get video info
		videoInfo = cast(MetaData*)videoBuffer;

		// Go to actual video buffer
		videoBuffer += videoInfo.videoBufferOffset;
	}

	void putChar(char c) {
		if (c == '\t') {
			videoInfo.xpos += TABSTOP;
		}
		else if (c != '\n' && c != '\r') {
			ubyte* ptr = cast(ubyte*)videoBuffer;
			ptr += (videoInfo.xpos + (videoInfo.ypos * videoInfo.width)) * 2;

			// Set the current piece of video memory to the character
			*(ptr) = c & 0xff;
			*(ptr + 1) = videoInfo.colorAttribute;

			// Increment
			videoInfo.xpos++;
		}

		// check for end of line, or newline
		if (c == '\n' || c == '\r' || videoInfo.xpos >= videoInfo.width) {
			videoInfo.xpos = 0;
			videoInfo.ypos++;

			while (videoInfo.ypos >= videoInfo.height) {
				scroll(1);
			}
		}
	}

	void putString(char[] string) {
		foreach(c; string) {
			putChar(c);
		}
	}

	void getPosition(out uint x, out uint y) {
		x = videoInfo.xpos;
		y = videoInfo.ypos;
	}

	void setPosition(uint x, uint y) {
		videoInfo.xpos = x;
		videoInfo.ypos = y;

		if (videoInfo.xpos >= videoInfo.width) {
			videoInfo.xpos = videoInfo.width - 1;
		}

		if (videoInfo.ypos >= videoInfo.height) {
			videoInfo.ypos = videoInfo.height - 1;
		}
	}

	void clear() {
		ubyte* ptr = cast(ubyte*)videoBuffer;

		for (int i; i < videoInfo.width * videoInfo.height * 2; i += 2) {
			*(ptr + i) = 0x00;
			*(ptr + i + 1) = videoInfo.colorAttribute;
		}

		videoInfo.xpos = 0;
		videoInfo.ypos = 0;
	}

	void scroll(uint numLines) {
		ubyte* ptr = cast(ubyte*)videoBuffer;

		if (numLines >= videoInfo.height) {
			clear();
			return;
		}

		int cury = 0;
		int offset1 = 0;
		int offset2 = numLines * videoInfo.width;

		// Go through and shift the correct amount
		for ( ; cury <= videoInfo.height - numLines; cury++) {
			for (int curx = 0; curx < videoInfo.width; curx++) {
				*(ptr + (curx + offset1) * 2)
					= *(ptr + (curx + offset1 + offset2) * 2);
				*(ptr + (curx + offset1) * 2 + 1)
					= *(ptr + (curx + offset1 + offset2) * 2 + 1);
			}

			offset1 += videoInfo.width;
		}

		// clear remaining lines
		for ( ; cury <= videoInfo.height; cury++) {
			for (int curx = 0; curx < videoInfo.width; curx++) {
				*(ptr + (curx + offset1) * 2) = 0x00;
				*(ptr + (curx + offset1) * 2 + 1) = 0x00;
			}
		}

		videoInfo.ypos -= numLines;
		if (videoInfo.ypos < 0) {
			videoInfo.ypos = 0;
		}
	}

	void resetColor() {
		videoInfo.colorAttribute = DEFAULTCOLORS;
	}

	void forecolor(Color clr) {
		videoInfo.colorAttribute = (videoInfo.colorAttribute & 0xf0) | clr;
	}

	Color forecolor() {
		ubyte clr = videoInfo.colorAttribute & 0xf;
		return cast(Color)clr;
	}

	void backcolor(Color clr) {
		videoInfo.colorAttribute = (videoInfo.colorAttribute & 0x0f) | (clr << 4);
	}

	Color backcolor() {
		ubyte clr = videoInfo.colorAttribute & 0xf0;
		clr >>= 4;
		return cast(Color)clr;
	}

	uint width() {
		return videoInfo.width;
	}

	uint height() {
		return videoInfo.height;
	}

private:

	MetaData* videoInfo;

	//Gib video;
	ubyte* videoBuffer;
}
