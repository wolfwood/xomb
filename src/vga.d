/** VGA.d
This file contains information for printing to the screen and communicating with the graphics card
through VGA.
*/

module vga;

import system;
import std.c.stdarg;
import gcc.builtins;
import util;

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

private
{
	template ExtractString(char[] format)
	{
		static if(format.length == 0)
		{
			const size_t ExtractString = 0;
		}
		else static if(format[0] is '{')
		{
			static if(format.length > 1 && format[1] is '{')
				const size_t ExtractString = 2 + ExtractString!(format[2 .. $]);
			else
				const size_t ExtractString = 0;
		}
		else
			const size_t ExtractString = 1 + ExtractString!(format[1 .. $]);
	}
	
	template ExtractFormatStringImpl(char[] format)
	{
		static assert(format.length !is 0, "Unterminated format specifier");
	
		static if(format[0] is '}')
			const ExtractFormatStringImpl = 0;
		else
			const ExtractFormatStringImpl = 1 + ExtractFormatStringImpl!(format[1 .. $]);
	}
	
	template CheckFormatAgainstType(char[] rawFormat, size_t idx, T)
	{
		const char[] format = rawFormat[1 .. idx];
		
		static if(isIntType!(T))
		{
			static assert(format == "" || format == "x" || format == "X" || format == "u" || format == "U",
				"Invalid integer format specifier '" ~ format ~ "'");
		}
	
		const size_t res = idx;
	}
	
	template ExtractFormatString(char[] format, T)
	{
		const ExtractFormatString = CheckFormatAgainstType!(format, ExtractFormatStringImpl!(format), T).res;
	}
	
	template StripDoubleLeftBrace(char[] s)
	{
		static if(s.length is 0)
			const char[] StripDoubleLeftBrace = "";
		else static if(s.length is 1)
			const char[] StripDoubleLeftBrace = s;
		else
		{
			static if(s[0 .. 2] == "{{")
				const char[] StripDoubleLeftBrace = "{" ~ StripDoubleLeftBrace!(s[2 .. $]);
			else
				const char[] StripDoubleLeftBrace = s[0] ~ StripDoubleLeftBrace!(s[1 .. $]);
		}
	}
	
	template MakePrintString(char[] s)
	{
		const char[] MakePrintString = "printString(\"" ~ StripDoubleLeftBrace!(s) ~ "\", \"\");\n";
	}
	
	template MakePrintOther(T, char[] fmt, size_t idx)
	{
		static if(isIntType!(T))
			const char[] MakePrintOther = "printInt(args[" ~ idx.stringof ~ "], \"" ~ fmt ~ "\");\n";
		else static if(isCharType!(T))
			const char[] MakePrintOther = "printChar(args[" ~ idx.stringof ~ "], \"" ~ fmt ~ "\");\n";
		else static if(isStringType!(T))
			const char[] MakePrintOther = "printString(args[" ~ idx.stringof ~ "], \"" ~ fmt ~ "\");\n";
		else static if(isFloatType!(T))
			const char[] MakePrintOther = "printFloat(args[" ~ idx.stringof ~ "], \"" ~ fmt ~ "\");\n";
		else static if(isPointerType!(T))
			const char[] MakePrintOther = "printPointer(args[" ~ idx.stringof ~ "], \"" ~ fmt ~ "\");\n";
		else
			static assert(false, "I don't know how to handle argument " ~ idx.stringof ~ " of type '" ~ T.stringof ~ "'.");
	}
	
	template ConvertFormatImpl(char[] format, size_t argIdx, Types...)
	{
		static if(format.length == 0)
		{
			static assert(argIdx == Types.length, "More parameters than format specifiers");
			const char[] res = "";
		}
		else
		{
			static if(format[0] is '{')
			{
				static if(format.length > 1 && format[1] is '{')
				{
					const idx = ExtractString!(format);
					const char[] res = MakePrintString!(format[0 .. idx]) ~
						ConvertFormatImpl!(format[idx .. $], argIdx, Types).res;
				}
				else
				{
					static assert(argIdx < Types.length, "More format specifiers than parameters");
					const idx = ExtractFormatString!(format, Types[argIdx]);
					const char[] res = MakePrintOther!(Types[argIdx], format[1 .. idx], argIdx) ~
						ConvertFormatImpl!(format[idx + 1 .. $], argIdx + 1, Types).res;
				}
			}
			else
			{
				const idx = ExtractString!(format);
				const char[] res = MakePrintString!(format[0 .. idx]) ~
					ConvertFormatImpl!(format[idx .. $], argIdx, Types).res;
			}
		}
	}
	
	template ConvertFormat(char[] format, Types...)
	{
		const char[] ConvertFormat = ConvertFormatImpl!(format, 0, Types).res;
	}
}

/** This structure contains informatino aobut the console, including
the number of columns and lines a standard screen should contain.
Also, it contains information about the standard and default colors, as well as the
initial position for the cursor when the kernel first executes.
*/
struct Console
{
static:
	/// The number of columns a standard screen is wide.
	const uint Columns = 80;
	
	/// The number of lines contained in a standard screen.
	const uint Lines = 24;
	// The default color for the text the kernel will use when first printing out.
	const ubyte DefaultColors = Color.LightGray;
	/// A pointer to the beginning of video memory, so the kernel can be gin writing to the screen.
	private ubyte* VideoMem = cast(ubyte*)0xB8000;
	/// The initial x-position of the cursor.
	private int xpos = 0;
	/// The initial y-position of the cursor.
	private int ypos = 0;
	/// The default set of colors the kernel is capable of using when printing to the screen.
	private ubyte colors = DefaultColors;

	/**
	This method clears the screen and returns the cursor to its default position.
	*/
	void cls()
	{
		/// Set all pieces of video memory to nothing.
		for(int i = 0; i < Columns * Lines * 2; i++)
			volatile *(VideoMem + i) = 0;

		xpos = 0;
		ypos = 0;
	}

	/**
	This method places a character (c) on the screen at the current cursor location.
		Params:
			c = The character you wish to print to the screen.
	*/
	void putchar(char c)
	{
		/// Check to make sure that c is not a standard escape sequence.
		if(c == '\n' || c == '\r')
		{
			/// If it is, increase the cursor's y-position, thus creating a new line.
			newline:
				xpos = 0;
				ypos++;

				/// If the printing has reached the end of the screen, set the y-cursor to the top of the screen.
				if(ypos >= Lines)
					scrollDisplay(1);

				return;
		}

		/// Set the current piece of video memory to the character to print.
		volatile *(VideoMem + (xpos + ypos * Columns) * 2) = c & 0xFF;
		volatile *(VideoMem + (xpos + ypos * Columns) * 2 + 1) = colors;
	
		/// Increase the cursor position.
		xpos++;
	
		/// If you have reached the end of the screen, create a new line (declared above).
		if(xpos >= Columns)
			goto newline;
	}
	
	/**
	Put some raw, unformatted string data to the screen.
	
	Params:
		s = The string to output.
	*/
	void putstr(char[] s)
	{
		foreach(c; s)
			putchar(c);
	}
	
	/**
	This function sets the console colors back to their defaults.
	*/
	void resetColors()
	{
	    colors = DefaultColors;
	}

	/**
	This function sets the forecolor (font color) to the given color.
		Params:
			newcol = The new color to set the font color to.
	*/
	void setForeColor(Color newcol)
	{
		colors &= newcol | 0xF0;
	}

	
	/**
	 Sets the current text background to a new color.
		Params:
			newcol = The new color to set the background color to.
	*/
	void setBackColor(Color newcol)
	{
		colors &= (newcol << 4) | 0x0F;
	}

	/**
	Allows, in one function call, to set both the background and text color.
		Params:
			forecolor = The color to set the text color to.
			backcolor = The color to set the background color to.
	*/
	void setColors(Color forecolor, Color backcolor)
	{
		colors = (forecolor & 0x0F) | (backcolor << 4);
	}

	/**
	This function scrolls the entire screen, allowing the operating system to extend beyond
	the length of a standard screen.
		Params:
			numlines = The number of lines that should be added to the bottom of the screen
				after the scrolling is complete.
	*/
	void scrollDisplay(int numlines)
	{
		/// The function received no lines. Do nothing.
		if(numlines <= 0)
			return;
	
		/// If you cannot increase that far, clear the screen, instead of using the processor
		/// power to go through each line.
		if(numlines >= Lines)
		{
			cls();
			return;
		}

		int cury = 0;
		int offset1 = 0;
		int offset2 = numlines * Columns;

		/// Go through everything in memory and copy it the proper amount
		/// to increase the number of lines on the screen.
		for(; cury < Lines - numlines; cury++)
		{
			for(int curx = 0; curx < Columns; curx++)
			{
				*(VideoMem + (curx + offset1) * 2) = *(VideoMem + (curx + offset1 + offset2) * 2);
				*(VideoMem + (curx + offset1) * 2 + 1) = *(VideoMem + (curx + offset1 + offset2) * 2 + 1);
			}

			offset1 += Columns;
		}

		for(; cury < Lines; cury++)
		{
			for(int curx = 0; curx < Columns; curx++)
			{
				*(VideoMem + (curx + offset1) * 2) = 0x00;
				*(VideoMem + (curx + offset1) * 2 + 1) = 0x00;
			}

			offset1 += Columns;
	    }
	
		ypos -= numlines;
	
		if(ypos < 0)
			ypos = 0;
	}

	void printInt(long i, char[] fmt)
	{
		char[20] buf;
		
		if(fmt.length is 0)
			putstr(itoa(buf, 'd', i));
		else if(fmt[0] is 'd' || fmt[0] is 'D')
			putstr(itoa(buf, 'd', i));
		else if(fmt[0] is 'u' || fmt[0] is 'U')
			putstr(itoa(buf, 'u', i));
		else if(fmt[0] is 'x' || fmt[0] is 'X')
			putstr(itoa(buf, 'x', i));
	}
	
	void printFloat(real f, char[] fmt)
	{
		putstr("?float?");
	}
	
	void printChar(dchar c, char[] fmt)
	{
		putchar(c);
	}

	void printString(T)(T s, char[] fmt)
	{
		static assert(isStringType!(T));
		putstr(s);
	}

	void printPointer(void* p, char[] fmt)
	{
		//putstr("0x");
		char[20] buf;
		putstr(itoa(buf, 'x', cast(ulong)p));
	}

	template kprintf(char[] Format)
	{
		void kprintf(Args...)(Args args)
		{
			mixin(ConvertFormat!(Format, Args));
		}
	}

	template kprintfln(char[] Format)
	{
		void kprintfln(Args...)(Args args)
		{
			mixin(ConvertFormat!(Format, Args));
			putchar('\n');
		}
	}
}

/// Create aliases so that we do not have to constantly call "Console.kprintf," but can simply call "printf."
alias Console.kprintf kprintf;
alias Console.kprintfln kprintfln;

extern(C) void kprintString(char* s)
{
	kprintfln!("{}")(toString(s));
}

/**
This function converts an integer to a string, depending on the base passed in.
	Params:
		buf = The function will save the translated string into this character array.
		base = The base of the integer value. If "d," it will be assumed to be decimal. If "x," the integer
			will be hexadecimal.
		d = The integer to translate.
	Returns: The translated string in a character array.
*/
char[] itoa(char[] buf, char base, long d)
{
	size_t p = buf.length - 1;
	size_t startIdx = 0;
	ulong ud = d;
	bool negative = false;

	int divisor = 10;

	// If %d is specified and D is minus, put `-' in the head.
	if(base == 'd' && d < 0)
	{
		negative = true;
		ud = -d;
	}
	else if(base == 'x')
		divisor = 16;

	// Divide UD by DIVISOR until UD == 0.
	do
	{
		int remainder = ud % divisor;
		buf[p--] = (remainder < 10) ? remainder + '0' : remainder + 'a' - 10;
	}
	while (ud /= divisor)

	if(negative)
		buf[p--] = '-';

	return buf[p + 1 .. $];
}