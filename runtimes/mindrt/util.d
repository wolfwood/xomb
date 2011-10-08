/*
 * util.d
 *
 * This module contains helpful functions found necessary by the runtime and gcc.
 * contains: itoa, memcpy, memset, memmove, memcmp, strlen, isnan, toString
 *
 * License: Public Domain
 *
 */

module mindrt.util;

public import mindrt.libd;

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


/**
This function determines the size of a passed-in string.
	Params:
		s = A pointer to the beginning of a character array, declaring a string.
	Returns: The size of the string in size_t format.
*/
size_t strlen(char* s)
{
	size_t i = 0;
	for( ; *s != 0; i++, s++){}
	return i;
}

/**
This function takes in a character pointer and returns a character array, or a string.
	Params:
		s = A pointer to the character(s) you wish to translate to a string.
	Returns: A character array (string) containing the information.
*/
char[] toString(char* s)
{
	return s[0 .. strlen(s)];
}

/**
This function checks to see if a floating point number is a NaN.
	Params:
		e = The value / piece of information you would like to check for number status.
	Returns:
		0 if it isn't a NaN, non-zero if it is.
*/
int isnan(real e)
{
    ushort* pe = cast(ushort *)&e;
    ulong*  ps = cast(ulong *)&e;

    return (pe[4] & 0x7FFF) == 0x7FFF &&
	    *ps & 0x7FFFFFFFFFFFFFFF;
}
