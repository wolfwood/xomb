/*
 * util.d
 *
 * This module contains helpful functions found necessary by the runtime and gcc.
 * contains: itoa, memcpy, memset, memmove, memcmp, strlen, isnan, toString
 *
 * License: Public Domain
 *
 */

module util;

public import libd;

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

// Some uniformly distributed hash function
// Reference: http://www.concentric.net/~Ttwang/tech/inthash.htm
hash_t hash(hash_t value) {
  static if (hash_t.sizeof == 4) {
    // 32 bit hash function
    // The commented lines are equivalent to the following line

    int c2 = 0x27d4eb2d;  // A prime number or odd constant

    value = (value ^ 61) ^ (value >>> 16);

    // value = value * 9
    value = value + (value << 3);

    value = value ^ (value >>> 4);

    value = value * c2;

    value = value ^ (value >>> 15);

    return value;
  }
  else static if (hash_t.sizeof == 8) {
    // 64 bit hash function
    // The commented lines are equivalent to the following line

    // value = (value << 21) - value - 1;
    // NOTE: ~value == -value - 1
    value = ~value + (value << 21);

    value = value ^ (value >>> 24);

    // value = value * 265; // That is, value * (1 + 8 + 256)
    value = (value + (value >> 3)) + (value << 8);

    value = value ^ (value >>> 14);

    // value = value * 21; // That is, value * (1 + 4 + 16)
    value = (value + (value << 2)) + (value << 4);

    value = value ^ (value >>> 28);
    value = value + (value << 31);

    return value;
  }
  else {
    static assert(false, "Need a hash function.");
  }
}
