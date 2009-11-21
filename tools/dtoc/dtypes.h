
// D primitive types
typedef unsigned char ubyte;
typedef char byte;

typedef unsigned short ushort;

typedef unsigned int uint;

typedef unsigned long long ulong;

#include <stddef.h>
#include <string.h>

// D dynamic arrays
struct _d_array {
	size_t foo;
	size_t foo2;
};

typedef struct _d_array Array;

struct _d_string {
	size_t length;
	char* ptr;
};

typedef struct _d_string String;

char* toCString(String* dstring) {
	return NULL;
}

String newDString(char* cstring) {
	String foo;
	foo.length = strlen(cstring);
	foo.ptr = cstring;
	return foo;
}

void toDString(String* dstring, char* cstring) {
	dstring->length = strlen(cstring);
	dstring->ptr = cstring;
}
