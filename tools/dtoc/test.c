#include "dtypes.h"
#include <stdio.h>
#include <malloc.h>

void print(char*, uint);
void printD(String s);

String printFoo(String s) {
	print(s.ptr, s.length);

	toDString(&s, "hello world");
//	s.ptr = "hello world";
//	s.length = 11;

	String s2 = newDString("HEY");
   	printD(s2);

	return s;
}
