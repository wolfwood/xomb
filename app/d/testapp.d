/* testapp.d

   Example application to be used with XOmB

*/

module testapp;

import user.syscall;
import user.ramfs;

import console;

import libos.ramfs;
import libos.keyboard;

import user.keycodes;

void main() {

	Console.initialize();
	Console.backcolor = Color.Black; 
	Console.forecolor = Color.Green;

	Console.putString("\nWelcome to XOmB\n");
	Console.putString("---------------\n\n");

	Console.backcolor = Color.Black; 
	Console.forecolor = Color.Red;

	Console.putString("What to do...\n");

	Console.forecolor = Color.LightGray;

	Console.putString("\n > ");

	Keyboard.initialize();
	

	char[128] str;
	uint pos = 0;

	bool released;
	for(;;) {
		Key key = Keyboard.nextKey(released);
		if (!released) {
			if (key == Key.Return) {
				Console.putChar('\n');

				if (pos != 0) {
					// interpret str
					interpret(str[0..pos]);
				}

				// print prompt
				Console.putString(" > ");

				// go back to start
				pos = 0;
			}
			else if (key == Key.Backspace) {
				if (pos > 0) {
					Point pt;
					pt = Console.position;
					Console.position(pt.x-1, pt.y);
					Console.putChar(' ');
					Console.position(pt.x-1, pt.y);
					pos--;
				}
			}
			else {
				char translate = Keyboard.translateKey(key);
				if (translate != '\0' && pos < 128) {
					str[pos] = translate;
					Console.putChar(translate);
					pos++;
				}
			}
		}
	}
	Console.putString("Done");
}

bool streq(char[] stra, char[] strb) {
	if (stra.length != strb.length) {
		return false;
	}

	foreach(size_t i, c; stra) {
		if (strb[i] != c) {
			return false;
		}
	}

	return true;
}

void interpret(char[] str) {
	char[] argument;
	char[][10] arguments;
	char[] cmd = str;
	int last = 0;
	int argc = 0;
	foreach(size_t i, c; str) {
		if (c == ' ') {
			if (argument is null) {
				argument = str[i+1..$];
				cmd = str[0..i];
			}

			if (argc < 10) {
				arguments[argc] = str[last..i];
				argc++;
			}
			else {
				break;
			}
			last = i + 1;
		}
	}

	if (argc < 10) {
		arguments[argc] = str[last..$];
		argc++;
	}

	if (streq(cmd, "clear")) {
		Console.clear();
	}
	else if (streq(cmd, "ls")) {
		// Open current directory
		
		// if there is an argument... we should parse it
		char[] listDirectory;
		if (argument.length > 0) {
			if (argument.length == 1 && argument[0] == '.') {
				listDirectory = workingDirectory;
			}
			else {
				createArgumentPath(argument);
				listDirectory = argumentPath;
			}
		}
		else {
			listDirectory = workingDirectory;
		}
		Directory d = Directory.open(listDirectory);

		int pos = 0;

		// Print items in directory
		foreach(DirectoryEntry dirent;d) {
			char[] f = dirent.name;
			if ((pos + f.length) >= Console.width()) {
				Console.putString("\n");
				pos = 0;
			}
			if (dirent.flags & Directory.Mode.Directory) {
				Console.forecolor = Color.LightBlue;
			}
			if (dirent.flags & Directory.Mode.Softlink) {
				Console.forecolor = Color.LightCyan;
			}
			if (dirent.flags & Directory.Mode.Executable) {
				Console.forecolor = Color.LightGreen;
			}
			Console.putString(f);
			Console.forecolor = Color.LightGray;
			if ((pos + f.length + 2) < Console.width()) {
				Console.putString("  ");
			}
			pos += f.length + 2;
		}
		if (pos != 0) {
			Console.putString("\n");
		}
	}
	else if (streq(cmd, "ln")) {
		if (argc != 3) {
			Console.putString("Not the right number of arguments\n");
		}
		else {
			RamFS.link(arguments[1], arguments[2], 0);
		}
	}
	else if (streq(cmd, "pwd")) {
		// Print working directory
		Console.putString(workingDirectory);
		Console.putString("\n");
	}
	else if (streq(cmd, "cat")) {
		// Open the file in the argument and print it to the screen

		if (argument.length > 0) {
			createArgumentPath(argument);

			// Open this file
			Gib g = RamFS.open(argumentPath, 0);

			// Write out the stuff in this file
			char[1] foo;
			int i;
			char* fooptr = cast(char*)g.ptr;
			for (i=0; i<g.length; i++) {
				foo[0] = *fooptr;
				fooptr++;
				Console.putString(foo);
			}

			g.close();
		}
	}
	else if (streq(cmd, "fault")) {
		ubyte* foo = cast(ubyte*)0x0;
		*foo = 2;
	}
	else if (streq(cmd, "cd")) {
		// Change directory
		if (argument.length > 0) {
			// Directory Up?
			if (argument.length == 2 && argument[0] == '.' && argument[1] == '.') {
				// Go up a directory
				size_t pos = 0;
				foreach_reverse(size_t i, c; workingDirectory) {
					if (c == '/') {
						pos = i;
						break;
					}
				}
				if (pos == 0) {
					pos = 1;
				}
				workingDirectory = workingDirectory[0..pos];
				return;
			}

			createArgumentPath(argument);

			workingDirectorySpace[0 .. argumentPath.length] = argumentPathSpace[0 .. argumentPath.length];
			workingDirectory = workingDirectorySpace[0 .. argumentPath.length];
		}
	}
	else {
		Console.putString("Unknown Command: ");
		Console.putString(cmd);
		Console.putString(".\n");
	}
}

void createArgumentPath(char[] argument) {
	int offset = 0;

	// Remove trailing slash
	if (argument[argument.length-1] == '/' && argument.length > 1) {
		argument.length = argument.length - 1;
	}

	// Determine if it is a relative path
	if (argument[0] != '/') {
		// Relative path
		offset = workingDirectory.length;
		argumentPathSpace[0] = '/';
	}

	// Determine if it is the '.'
	if (argument.length == 1 && argument[0] == '.') {
		argument = workingDirectory;
		offset = 0;
	}

	// append to the working directory
	if (offset > 1) {
		argumentPathSpace[1 .. offset] = workingDirectorySpace[1 .. offset];
		argumentPathSpace[offset] = '/';
		offset++;
	}

	// Append the argument
	foreach(size_t i, c; argument) {
		argumentPathSpace[i+offset] = c;
	}
	argumentPath = argumentPathSpace[0..argument.length+offset];
}

char[256] argumentPathSpace = "/";
char[] argumentPath = "/";

char[256] workingDirectorySpace = "/";
char[] workingDirectory = "/";
