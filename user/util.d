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
