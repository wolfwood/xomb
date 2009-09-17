module user.console;

enum ConsoleType {
	Buffer8Char8Attr,
}

struct ConsoleInfo {
	ConsoleType type;
	void* buffer;
	uint width;
	uint height;
}
