module user.util;

template Tuple(T...)
{
	alias T Tuple;
}

template Map(alias Templ, List...)
{
        static if(List.length == 0)
                alias Tuple!() Map;
        else
                alias Tuple!(Templ!(List[0]), Map!(Templ, List[1 .. $]))
Map;
}

template Reduce(alias Templ, List...)
{
        static assert(List.length > 0, "Reduce must be called on a list
of at least one element");

        static if(is(List[0]))
        {
                static if(List.length == 1)
                        alias List[0] Reduce;
                else
                        alias Reduce!(Templ, Tuple!(Templ!(List[0],
List[1]), List[2 .. $])) Reduce;
        }
        else
        {
                static if(List.length == 1)
                        const Reduce = List[0];
                else
                        const Reduce = Reduce!(Templ,
Tuple!(Templ!(List[0], List[1]), List[2 .. $]));
        }
}

template IsLower(char c)
{
        const bool IsLower = c >= 'a' && c <= 'z';
}

/**
See if a character is an uppercase character.
*/
template IsUpper(char c)
{
        const bool IsUpper = c >= 'A' && c <= 'Z';
}


template ToLower(char c)
{
        const char ToLower = IsUpper!(c) ? c + ('a' - 'A') : c;
}

/// ditto
template ToLower(char[] s)
{
        static if(s.length == 0)
                const ToLower = ""c;
        else
                const ToLower = ToLower!(s[0]) ~ s[1 .. $];
}


template ToUpper(char c)
{
        const char ToUpper = IsLower!(c) ? c - ('a' - 'A') : c;
}

/// ditto
template ToUpper(char[] s)
{
        static if(s.length == 0)
                const ToUpper = ""c;
        else
                const ToUpper = ToUpper!(s[0]) ~ s[1 .. $];
}


template Capitalize(char[] s)
{
        static if(s.length == 0)
                const char[] Capitalize = ""c;
        else
                const char[] Capitalize = ToUpper!(s[0]) ~ ToLower!(s[1
.. $]);
}


template Range(uint min, uint max)
{
        static if(min >= max)
                alias Tuple!() Range;
        else
                alias Tuple!(min, Range!(min + 1, max)) Range;
}

template Range(uint max)
{
        alias Range!(0, max) Range;
}


template Cat(T...)
{
	const Cat = T[0] ~ T[1];
}


template Bitfield(alias data, Args...){
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

		const char[] Getter = "public " ~ typeStr ~ " " ~ Name ~ "() { return ( " ~ nameStr ~ " >> " ~ Itoh!(offset) ~ " ) & " ~ Itoh!(Mask) ~ "; }";

		const char[] Setter = "public void " ~ Name ~ "(" ~ typeStr ~ " val) { " ~ nameStr ~ " = (" ~ nameStr ~ " & " ~ Itoh!(~(Mask << offset)) ~ ") | ((val & " ~ Itoh!(Mask) ~ ") << " ~ Itoh!(offset) ~ "); }";

		const char[] Ret = Getter ~ Setter ~ BitfieldImpl!(typeStr, nameStr, offset + Size, Args[2 .. $]).Ret;
	}
}

template Bitmask(long size){
	const long Bitmask = (1L << size) - 1;
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