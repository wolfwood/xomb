import tango.io.Stdout;

extern(C) char[] printFoo(char[] s);

void printInD(char[] str) {
	Stdout(str).newline;
}

extern(C) void printD(char[] str) {
	Stdout(str).newline;
}

extern(C) void print(char* foo, uint len) {
	Stdout(foo[0..len]).newline;
}

void main() {
	char[] foo = "woo";
	void* fooptr = cast(void*)foo;
	foo = printFoo(foo);
	Stdout(fooptr).newline;
	Stdout(*((cast(size_t*)fooptr)-1)).newline;
	printInD(foo);
}
