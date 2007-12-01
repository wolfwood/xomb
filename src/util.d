module util;

template Tuple(T...)
{
	alias T Tuple;
}

template isArrayType(T : T[])
{
	const isArrayType = true;
}

template isArrayType(T)
{
	const isArrayType = false;
}

template Bitfield(alias data, Args...)
{
	static assert(!(Args.length & 1), "Bitfield arguments must be an even number");
	const char[] Bitfield = BitfieldShim!((typeof(data)).stringof, data, Args).Ret;
	
	pragma(msg, Bitfield);
}

// Odd bug in D templates -- putting "data.stringof" as a template argument gives it the
// string of the type, rather than the string of the symbol.  This shim works around that.
template BitfieldShim(char[] typeStr, alias data, Args...)
{
	const char[] Name = data.stringof;
	const char[] Ret = BitfieldImpl!(typeStr, Name, 0, Args).Ret;
}

template BitfieldImpl(char[] typeStr, char[] nameStr, int offset, Args...)
{
	static if(Args.length == 0)
		const char[] Ret = "";
	else
	{
		const Name = Args[0];
		const Size = Args[1];
		const Mask = Bitmask!(Size);

		const char[] Getter = "public " ~ typeStr ~ " " ~ Name ~ "() { return ( " ~
			nameStr ~ " >> " ~ Itoh!(offset) ~ " ) & " ~ Itoh!(Mask) ~ "; }";

		const char[] Setter = "public void " ~ Name ~ "(" ~ typeStr ~ " val) { " ~
			nameStr ~ " = (" ~ nameStr ~ " & " ~ Itoh!(~(Mask << offset)) ~ ") | ((val & " ~
			Itoh!(Mask) ~ ") << " ~ Itoh!(offset) ~ "); }";

		const char[] Ret = Getter ~ Setter ~ BitfieldImpl!(typeStr, nameStr, offset + Size, Args[2 .. $]).Ret;
	}
}

template Itoa(long i)
{
	static if(i < 0)
		const char[] Itoa = "-" ~ IntToStr!(-i, 10);
	else
		const char[] Itoa = IntToStr!(i, 10);
}

template Itoh(long i)
{
	const char[] Itoh = "0x" ~ IntToStr!(i, 16);
}

template Digits(long i)
{
	const char[] Digits = "0123456789abcdefghijklmnopqrstuvwxyz"[0 .. i];
}

template IntToStr(ulong i, int base)
{
	static if(i >= base)
		const char[] IntToStr = IntToStr!(i / base, base) ~ Digits!(base)[i % base];
	else
		const char[] IntToStr = "" ~ Digits!(base)[i % base];
}

template Bitmask(long size)
{
	const long Bitmask = (1L << size) - 1;
}