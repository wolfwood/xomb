#include <syscall.h>
#include <stdlib.h>

void main() {
	int foo = add(3,4);

	char* ptr = (char*)0x900000;
	allocPage((void*)ptr);

	int size = 5000;
	char* a_ptr = (char*)malloc(sizeof(char) * size);

	if (a_ptr == NULL) {
		return;
	}

	int i;
	for (i=0; i<4096; i++) {
		*ptr = 10;
		ptr++;
	}

	char* subptr = a_ptr;
	for (i=0; i<size; i++) {
		*subptr = 10;
		subptr++;
	}

	a_ptr = (char*)malloc(sizeof(char) * 20);
	for (i=0; i<20; i++) {
		*a_ptr = 10;
		a_ptr++;
	}
}
