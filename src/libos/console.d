module libos.console;

import user.syscall;



/** This structure contains hexadecimal values equivalent to various types
of colors for printing to the screen, allowing the kernel to switch colors easily
without an asinine amount of switching between hexadecimal and not hexadecimal.
*/
enum Color : ubyte
{
	Black        = 0x00,
	LowBlue      = 0x01,
	LowGreen     = 0x02,
	LowCyan      = 0x03,
	LowRed       = 0x04,
	LowMagenta   = 0x05,
	Brown        = 0x06,
	LightGray    = 0x07,
	DarkGray     = 0x08,
	HighBlue     = 0x09,
	HighGreen    = 0x0A,
	HighCyan     = 0x0B,
	HighRed      = 0x0C,
	HighMagenta  = 0x0D,
	Yellow       = 0x0E,
	White        = 0x0F
}

struct Console {

static:

	void init()
	{
		cInfo = initConsole();
	}

	void setPosition(int x, int y)
	{
		if ((x < 0 || x >= cInfo.xMax) &&
			(y < 0 || y >= cInfo.yMax))
		{
			return;
		}

		// XXX: LOCK!!!
		cInfo.xPos = x;
		cInfo.yPos = y;
	}

	void getPosition(out int x, out int y)
	{
		x = cInfo.xPos;
		y = cInfo.yPos;
	}

	void clear()
	{
		// LOCK
		for (int i = 0; i < cInfo.xMax * cInfo.yMax * 2; i++)
		{
			volatile *(cInfo.buffer + i) = 0;

			cInfo.xPos = 0;
			cInfo.yPos = 0;
		}
	}

	void printString(char[] str)
	{
		// LOCK
		putString(str);
	}

	void printChar(char c)
	{
		// LOCK
		putChar(c);
	}

	void resetColors()
	{
		curColor = Color.LightGray;
	}

	void setForeColor(Color newColor)
	{
		curColor &= newColor | 0xF0;
	}

	void setBackColor(Color newColor)
	{
		curColor &= (newColor << 4) | 0x0F;
	}

	void setColors(Color foreColor, Color backColor)
	{
		curColor = (foreColor & 0x0F) | (backColor << 4);
	}

	void scroll(int amt)
	{
		// do nothing for invalid line count
		if (amt <= 0) { return; }

		// just clear if it wants to scroll everything
		if (amt >= cInfo.yMax) { clear(); return; }

		// go through and copy the proper amount to increase
		// the lines on the screen
		int cury = 0;
		int offset1 = 0 * cInfo.xMax;
		int offset2 = amt * cInfo.xMax;

		for(; cury <= cInfo.yMax - amt; cury++)
		{
			for (int curx = 0; curx < cInfo.xMax; curx++)
			{
				*(cInfo.buffer + (curx + offset1) * 2) =
					*(cInfo.buffer + (curx + offset1 + offset2) * 2);
				*(cInfo.buffer + (curx + offset1) * 2 + 1) =
					*(cInfo.buffer + (curx + offset1 + offset2) * 2 + 1);
			}

			offset1 += cInfo.xMax;
		}

		for(; cury <= cInfo.yMax; cury++)
		{
			for (int curx = 0; curx < cInfo.xMax; curx++)
			{
				*(cInfo.buffer + (curx + offset1) * 2) = 0x00;
				*(cInfo.buffer + (curx + offset1) * 2 + 1) = 0x00;
			}

			offset1 += cInfo.xMax;
		}

		cInfo.yPos -= amt;

		if (cInfo.yPos < 0)
		{
			cInfo.yPos = 0;
		}
	}

private:

	const uint Tabstop = 4;

	ConsoleInfo cInfo;

	ubyte curColor = Color.LightGray;


	// non-locked functions
	void putString(char[] str)
	{
		foreach(chr; str)
		{
			printChar(chr);
		}
	}

	void putChar(char c)
	{
		if (c == '\n' || c == '\r')
		{
			// this will force a new line
			cInfo.xPos = cInfo.xMax;
		}
		else if (c == '\t')
		{
			// increment by the tab length
			cInfo.xPos += Tabstop;
		}
		else
		{
			volatile *(cInfo.buffer + (cInfo.xPos + (cInfo.yPos * cInfo.xMax)) * 2) = c & 0xFF;
			volatile *(cInfo.buffer + (cInfo.xPos + (cInfo.yPos * cInfo.xMax)) * 2 + 1) = curColor;

			cInfo.xPos++;
		}

		if (cInfo.xPos >= cInfo.xMax)
		{
			cInfo.xPos = 0;
			cInfo.yPos ++;

			if (cInfo.yPos >= cInfo.yMax)
			{
				scroll(1);
			}
		}
	}



}
