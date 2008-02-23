/**
This file contains common, global methods used widely by the system.
*/

module system;

/**
This function copies data from a source piece of memory to a destination piece of memory.
	Params:
		dest = A pointer to the piece of memory serving as the copy destination.
		src = A pointer to the piece of memory serving as the copy source.
		count = The number of bytes to copy form src to dest.
	Returns: A void pointer to the start of the destination data (dest).
*/
void* memcpy(void* dest, void* src, size_t count)
{
	ubyte* d = cast(ubyte*)dest;
	ubyte* s = cast(ubyte*)src;

	for(size_t i = count; count; count--, d++, s++)
		*d = *s;

	return dest;
}

/**
Memcpy and memmove only really have differences at the user level, where they have slightly
different semantics.  Here, they're pretty much the same.
*/
alias memcpy memmove;

/**
Compare two blocks of memory.

Params:
	a = Pointer to the first block.
	b = Pointer to the second block.
	n = The number of bytes to compare.

Returns:
	 0 if they are equal, < 0 if a is less than b, and > 0 if a is greater than b.
*/
long memcmp(void* a, void* b, size_t n)
{
	ubyte* str_a = cast(ubyte*)a;
	ubyte* str_b = cast(ubyte*)b;

	for(size_t i = 0; i < n; i++)
	{
		if(*str_a != *str_b)
			return *str_a - *str_b;

		str_a++;
		str_b++;
	}
	
	return 0;
}

/**
This function sets a particular piece of memory to a particular value.
	Params:
		addr = The address of the piece of memory you wish to write.
		val = The value you wish to write to memory.
		numBytes = The number of bytes you would like to write to memory.
*/
void memset(void *addr, ubyte val, uint numBytes){
     ubyte *data = cast(ubyte*) addr;

     for(int i = 0; i < numBytes; i++){
          data[i] = val;
     }
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

/**
Gets the value of the CPUID function for a given item.  See some sort of documentation on
how to use the CPUID function.  There's way too much to document here.

	Params:
		func = The CPUID function.
	Returns:
		The result of the CPUID instruction for the given function.
*/
uint cpuid(uint func)
{
	asm
	{
		naked;
		"movl %%edi, %%eax";
		"cpuid";
		"movl %%edx, %%eax";
		"retq";
	}
}