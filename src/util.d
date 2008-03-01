module util;

/**
This method checks to see if the value stored in the bit number declared
by the input variable "bit" in the flag declared by the input
variable "flags" is set. Returns a 1 if it is set, returns a 0 if it is not set.
	Params:
		flags = The flags from the multiboot header the kernel wishes to check.
		bit = The number of the bit the kernel would like to check for data.
	Returns: Whether the bit "bit" in "flags" has a value (1 if it is set, 0 if it is not)
*/
uint CHECK_FLAG(uint flags, uint bit)
{
	return ((flags) & (1 << (bit)));
}

/**
Given a struct type, gives a tuple of strings of the names of fields in the struct.
*/
public template FieldNames(S, int idx = 0)
{
	static if(idx >= S.tupleof.length)
		alias Tuple!() FieldNames;
	else
		alias Tuple!(GetLastName!(S.tupleof[idx].stringof), FieldNames!(S, idx + 1)) FieldNames;
}

private template GetLastName(char[] fullName, int idx = fullName.length - 1)
{
	static if(idx < 0)
		const char[] GetLastName = fullName;
	else static if(fullName[idx] == '.')
		const char[] GetLastName = fullName[idx + 1 .. $];
	else
		const char[] GetLastName = GetLastName!(fullName, idx - 1);
}

template Tuple(T...)
{
	alias T Tuple;
}

template Bitfield(alias data, Args...)
{
	static assert(!(Args.length & 1), "Bitfield arguments must be an even number");
	const char[] Bitfield = BitfieldShim!((typeof(data)).stringof, data, Args).Ret;
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

template isStringType(T)
{
	const bool isStringType = is(T : char[]) || is(T : wchar[]) || is(T : dchar[]);
}

/**
Sees if a type is char, wchar, or dchar.
*/
template isCharType(T)
{
	const bool isCharType = is(T == char) || is(T == wchar) || is(T == dchar);
}

/**
Sees if a type is a signed or unsigned byte, short, int, or long.
*/
template isIntType(T)
{
	const bool isIntType = is(T == int) || is(T == uint) || is(T == long) || is(T == ulong) ||
							is(T == short) || is(T == ushort) || is(T == byte) || is(T == ubyte) /* || is(T == cent) || is(T == ucent) */;
}

/**
Sees if a type is float, double, or real.
*/
template isFloatType(T)
{
	const bool isFloatType = is(T == float) || is(T == double) || is(T == real);
}

/**
Sees if a type is an array.
*/
template isArrayType(T)
{
	const bool isArrayType = false;
}

template isArrayType(T : T[])
{
	const bool isArrayType = true;
}

/**
Sees if a type is an associative array.
*/
template isAAType(T)
{
	const bool isAAType = is(typeof(T.init.values[0])[typeof(T.init.keys[0])] == T);
}

/**
Sees if a type is a pointer.
*/
template isPointerType(T)
{
	const bool isPointerType = (is(typeof(*T)) && !isArrayType!(T)) || is(T == void*);
}

/**
Get to the bottom of any chain of typedefs!  Returns the first non-typedef'ed type.
*/
template realType(T)
{
	static if(is(T Base == typedef) || is(T Base == enum))
		alias realType!(Base) realType;
	else
		alias T realType;
}