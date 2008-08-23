/** VGA.d
This file contains information for printing to the screen and communicating with the graphics card
through VGA.
*/

module kernel.dev.vga;

import kernel.arch.locks;

import kernel.core.system;
import kernel.core.util;

import std.c.stdarg;
import gcc.builtins;


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
		else static if(isArrayType!(T))
			const char[] MakePrintOther = "printArray(args[" ~ idx.stringof ~ "], true, false);\n";
		else
			static assert(false, "I don't know how to handle argument " ~ idx.stringof ~ " of type '" ~ T.stringof ~ "'.");
	}
	
	template ConvertFormatImpl(char[] format, size_t argIdx, Types...)
	{
		static if(format.length == 0)
		{
			static assert(argIdx == Types	.length, "More parameters than format specifiers");
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

/** This structure contains information aobut the console, including
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
	/// The default color for the text the kernel will use when first printing out.
	const ubyte DefaultColors = Color.LightGray;
	/// A pointer to the beginning of video memory, so the kernel can begin writing to the screen.
	private ubyte* VideoMem = cast(ubyte*)0xffffffff800B8000;
	/// The initial x-position of the cursor.
	private int xpos = 0;
	/// The initial y-position of the cursor.
	private int ypos = 0;
	/// The default set of colors the kernel is capable of using when printing to the screen.
	private ubyte colors = DefaultColors;
	/// The width of a tab.  It's 4, goddammit.
	const Tabstop = 4;
	/// print lock and x/y coordinates lock
	kmutex printLock;
	kmutex coordLock;

	/**
	This method clears the screen and returns the cursor to its default position.
	*/
	void cls()
	{	
		printLock.lock();
		/// Set all pieces of video memory to nothing.
		for(int i = 0; i < Columns * Lines * 2; i++)
			volatile *(VideoMem + i) = 0;
		coordLock.lock();
		xpos = 0;
		ypos = 0;
		coordLock.unlock();
		printLock.unlock();
	}

	void getPosition(out int x, out int y)
	{
		coordLock.lock();
		x = xpos;
		y = ypos;
		coordLock.unlock();
	}

	void setPosition(int x, int y)
	{
		if (x < 0) { x = 0; }
		if (y < 0) { y = 0; }
		if (x >= Columns) { x = Columns-1; }
		if (y >= Lines) { y = Lines-1; }

		coordLock.lock();
		xpos = x;
		ypos = y;
		coordLock.unlock();
	}

	/**
	This method places a character (c) on the screen at the current cursor location.
		Params:
			c = The character you wish to print to the screen.
	*/
	private void putchar(char c)
	{
		/// Check to make sure that c is not a standard escape sequence.
		if(c == '\n' || c == '\r')
		{
			/// If it is, increase the cursor's y-position, thus creating a new line.
			newline:
				coordLock.lock();
				xpos = 0;
				ypos++;
				coordLock.unlock();

				/// If the printing has reached the end of the screen, set the y-cursor to the top of the screen.
				if(ypos >= Lines)
					scrollDisplay(1);

				return;
		}

		if(c == '\t')
		{
			coordLock.lock();
			xpos += Tabstop;
			coordLock.unlock();
		}
		else
		{
			// Set the current piece of video memory to the character to print.
			volatile *(VideoMem + (xpos + ypos * Columns) * 2) = c & 0xFF;
			volatile *(VideoMem + (xpos + ypos * Columns) * 2 + 1) = colors;

			// Increase the cursor position.
			coordLock.lock();
			xpos++;
			coordLock.unlock();
		}

		// If you have reached the end of the screen, create a new line (declared above).
		if(xpos >= Columns)
			goto newline;
	}
	
	/**
	Put some raw, unformatted string data to the screen.
	
	Params:
		s = The string to output.
	*/
	private void putstr(char[] s)
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
	private void scrollDisplay(int numlines)
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
	
		coordLock.lock();
		ypos -= numlines;
	
		if(ypos < 0)
			ypos = 0;
		coordLock.unlock();
	}

	private void printInt(long i, char[] fmt)
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
	
	private void printFloat(real f, char[] fmt)
	{
		putstr("?float?");
	}
	
	private void printChar(dchar c, char[] fmt)
	{
		putchar(c);
	}

	private void printString(T)(T s, char[] fmt)
	{
		static assert(isStringType!(T));
		putstr(s);
	}

	private void printPointer(void* p, char[] fmt)
	{
		putstr("0x");
		char[20] buf;
		putstr(itoa(buf, 'x', cast(ulong)p));
	}

	template kprintf(char[] Format, bool lock = true)
	{
		void kprintf(Args...)(Args args)
		{
			if (lock) {
				printLock.lock();
			}
			mixin(ConvertFormat!(Format, Args));
			if (lock) {
				printLock.unlock();
			}
		}
	}

	template kprintfln(char[] Format, bool lock = true)
	{
		void kprintfln(Args...)(Args args)
		{
			if (lock) {
				printLock.lock();
			}
			mixin(ConvertFormat!(Format, Args));
			putchar('\n');
			if (lock) {
				printLock.unlock();
			}
		}
	}
	 
	void printStruct(T)(ref T s, bool recursive = false, ulong indent = 0, bool lock = true)
	{
		if (lock)
		{
			printLock.lock();
		}

		static assert(is(T == struct), "printStruct - Type must be a struct");
		
		void tabs()
		{
			for(ulong i = 0; i < indent; i++)
				putchar('\t');
		}

		alias FieldNames!(T) fieldNames;
		
		tabs();
		indent++;

		kprintfln!(T.stringof ~ " ({})", false)(&s);

		foreach(i, _; s.tupleof)
		{
			static if(is(typeof(s.tupleof[i]) == struct) ||
				(isPointerType!(typeof(s.tupleof[i])) && is(typeof(*s.tupleof[i]) == struct)))
			{
				tabs();

				if(recursive)
				{
					putstr(fieldNames[i]);
					putstr(": ");

					static if(isPointerType!(typeof(s.tupleof[i])))
					{
						if(s.tupleof[i] is null)
							putstr("(null)\n");
						else
						{
							putchar('\n');
							printStruct(*s.tupleof[i], true, indent, false);
						}
					}
					else
					{
						putchar('\n');
						printStruct(s.tupleof[i], true, indent, false);
					}
				}
				else
				{
					static if(isPointerType!(typeof(s.tupleof[i])))
					{
						kprintfln!(fieldNames[i] ~ " = {x}", false)(s.tupleof[i]);
					}
					else
					{
						kprintfln!(fieldType.stringof ~ " " ~ fieldNames[i] ~ " (struct)", false)();
					}
				}
			}
			else
			{
				tabs();

				static if(isIntType!(typeof(s.tupleof[i])))
				{
					kprintfln!(fieldNames[i] ~ " = 0x{x}", false)(s.tupleof[i]);
				}
				else
				{
					kprintfln!(fieldNames[i] ~ " = {}", false)(s.tupleof[i]);
				}
			}
		}

		if (lock)
		{
			printLock.unlock();
		}
	}
	 
	void printArray(T)(T[] s, bool recursive = false, bool lock = true)
	{
		if (lock)
		{
			printLock.lock();
		}

		putstr("[ ");

		static assert (isArrayType!(T[]), "printArray - parameter needs to be an array");

		foreach(uint count, item; s)
		{
			static if (isArrayType!(typeof(item)))
			{
				printArray(item, true, false);
			}	
			else static if (isCharType!(T))
			{
				putchar(item);
			}
			else static if (is(T == struct))
			{
				printStruct(item, false, cast(ulong)0, false);
			}
			else static if (isSignedIntType!(T))
			{
				printInt(item, "d");
			}
			else static if (isUnsignedIntType!(T))
			{
				printInt(item, "u");
			}
			else static if (isPointerType!(T))
			{
				printPointer(item);
			}
			
			if (count!=(s.length-1))
			{				
				putstr(", ");
			}
			else
			{
				putstr(" ]");
			}
		}

		if (!recursive)
		{
			putstr("\n");
		}
		
		if (lock)
		{
			printLock.unlock();
		}
	}
}

/// Create aliases so that we do not have to constantly call "Console.kprintf," but can simply call "printf."
alias Console.kprintf kprintf;
alias Console.kprintfln kprintfln;
alias Console.printStruct printStruct;
alias Console.printArray printArray;

extern(C) void kprintString(char* s)
{
	kprintfln!("{}")(toString(s));
}

