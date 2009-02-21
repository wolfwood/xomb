module kernel.core.kprintf;

import kernel.dev.console;
import kernel.core.util;

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
		Console.putChar('\n');
	}
}

































private
{


	void printInt(long i, char[] fmt)
	{
		char[20] buf;

		if(fmt.length is 0)
			Console.putString(itoa(buf, 'd', i));
		else if(fmt[0] is 'd' || fmt[0] is 'D')
			Console.putString(itoa(buf, 'd', i));
		else if(fmt[0] is 'u' || fmt[0] is 'U')
			Console.putString(itoa(buf, 'u', i));
		else if(fmt[0] is 'x' || fmt[0] is 'X')
			Console.putString(itoa(buf, 'x', i));
	}

	void printFloat(real f, char[] fmt)
	{
		Console.putString("?float?");
	}

	void printChar(dchar c, char[] fmt)
	{
		Console.putChar(c);
	}

	void printString(T)(T s, char[] fmt)
	{
		static assert(isStringType!(T));
		Console.putString(s);
	}

	void printPointer(void* p, char[] fmt)
	{
		Console.putString("0x");
		char[20] buf;
		Console.putString(itoa(buf, 'x', cast(ulong)p));
	}

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



