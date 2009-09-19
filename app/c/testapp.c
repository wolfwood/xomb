#include <syscall.h>

void main() {
	int foo = add(3,4);

	char* ptr = (char*)0x900000;
	allocPage((void*)ptr);

	int i;
	for (i=0; i<4096; i++) {
		*ptr = 10;
		ptr++;
	}
}
