module user.console;

extern(C):

// This contains the hexidecimal values for various colors for printing to the screen.
enum Color : ubyte {
	Black		  = 0x00,
	Blue		  = 0x01,
	Green	      = 0x02,
	Cyan		  = 0x03,
	Red           = 0x04,
	Magenta       = 0x05,
	Yellow        = 0x06,
	LightGray     = 0x07,
	Gray          = 0x08,
	LightBlue     = 0x09,
	LightGreen    = 0x0A,
	LightCyan     = 0x0B,
	LightRed      = 0x0C,
	LightMagenta  = 0x0D,
	LightYellow   = 0x0E,
	White         = 0x0F
}

enum ConsoleType : int {
	Buffer8Char8Attr,
}

// The MetaData is the first page of the video Gib
// It will be shared with the user app.
struct MetaData {
	// Something to identify the layout of the console frame
	int consoleType = 0;

	// The cursor position
	int xpos = 0;
	int ypos = 0;

	int width;
	int height;

	// The total number of lines
	long globalY = 0;

	// The current color
	ubyte colorAttribute = Color.LightGray;

	ulong videoBufferOffset = 0;
}

