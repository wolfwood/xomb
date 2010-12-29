/* xsh.d

   XOmB Native Shell

*/

module xsh;

import user.syscall;

import console;
import libos.keyboard;
import user.keycodes;

import libos.libdeepmajik.threadscheduler;

import libos.fs.minfs;

void main() {
	Console.backcolor = Color.Black; 
	Console.forecolor = Color.Green;

	Console.putString("\nWelcome to XOmB\n");
	Console.putString(  "-=-=-=-=-=-=-=-\n\n");

	Console.backcolor = Color.Black; 
	Console.forecolor = Color.LightGray;

	MinFS.initialize();

	printPrompt();

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
				printPrompt();

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

void printPrompt() {
	Console.putString("root@localhost:");
	Console.putString(workingDirectory);
	Console.putString("$ ");
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
		/*char[] listDirectory;
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

		uint flags;
		if (exists(listDirectory, flags)) {
			if ((flags & Directory.Mode.Directory) == 0) {
				Console.putString("xsh: ls: Not a directory.\n");
				return;
			}
		}
		else {
			Console.putString("xsh: ls: Directory not found.\n");
			return;
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

		d.close();
		*/
	}
	else if (streq(cmd, "ln")) {
		/*if (argc != 3) {
			Console.putString("xsh: ln: Not the right number of arguments.\n");
			}
		else {
			RamFS.link(arguments[1], arguments[2], 0);
			}*/
	}
	else if (streq(cmd, "pwd")) {
		// Print working directory
		Console.putString(workingDirectory);
		Console.putString("\n");
	}
	else if (streq(cmd, "scat")) {
		if (argument.length > 0) {
			createArgumentPath(argument);

			File f = MinFS.open(argumentPath, cast(AccessMode)0);

			ulong* size = cast(ulong*)f.ptr;
			char[] data = (cast(char*)f.ptr)[ulong.sizeof..(ulong.sizeof + *size)];

			Console.putString(data);
		}

		// Open the file in the argument and print it to the screen
		/*
		if (argument.length > 0) {
			createArgumentPath(argument);

			uint flags;
			if (exists(argumentPath, flags)) {
				if ((flags & Directory.Mode.Directory) == 0) {
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
					return;
				}
				else {
					Console.putString("xsh: cat: File is a directory.\n");
				}
			}
			else {
				Console.putString("xsh: cat: File not found.\n");
			}
			}*/
	}
	else if (streq(cmd, "run")) {
		// Open the file, parse the ELF into a new address space, and execute
		
		if (argument.length > 0) {
			createArgumentPath(argument);

			AddressSpace child = createAddressSpace();

			File f = MinFS.open(argumentPath, AccessMode.Writable);
			
			populateChild(arguments[0..argc], child, f);

			yieldToAddressSpace(child);
		}

			/*
			uint flags;
			if (exists(argumentPath, flags)) {
				if ((flags & Directory.Mode.Directory) == 0) {
					// Open this file
					//Gib g = RamFS.open(argumentPath, 0);

					// create new address space
					uint eid = createEnv(argumentPath);

					// create stack gib
					//Syscall.gibOpen

					// create text gib


					// fill text from ELF


					// create data gib


					// fill text from ELF
					

					//g.close();

					
					yieldCPU(eid);

					return;
				}
				else {
					Console.putString("xsh: run: File is a directory.\n");
				}
			}
			else {
				Console.putString("xsh: run: Executable not found.\n");
			}
			}*/
	}
	else if (streq(cmd, "exit")) {
		exit(0);
	}
	else if (streq(cmd, "fault")) {
		ubyte* foo = cast(ubyte*)0x0;
		*foo = 2;
	}
	else if (streq(cmd, "cd")) {
		// Change directory
		/*
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

			// Determine if the directory is indeed a directory
			if (argumentPath.length != 1) {
				uint flags;
				if (exists(argumentPath, flags)) {
					if (flags & Directory.Mode.Directory) {
						// Is a directory, set working directory
						workingDirectorySpace[0 .. argumentPath.length] = argumentPathSpace[0 .. argumentPath.length];
						workingDirectory = workingDirectorySpace[0 .. argumentPath.length];
					}
					else {
						Console.putString("xsh: cd: Not a directory.\n");
						return;
					}
				}
				else {
					Console.putString("xsh: cd: Path does not exist.\n");
					return;
				}
			}			
			}*/
	}
	else {
		if (argument.length > 0) {		
			AddressSpace child = createAddressSpace();
			File infile = null, outfile = null;

			// XXX: really lame redirects
			if(argc > 2){
				if(arguments[argc-2] == ">"){
					outfile = MinFS.open(arguments[argc-1], AccessMode.Writable, true);	
					argc -= 2;
				}else if(arguments[argc-2] == "<"){
					infile = MinFS.open(arguments[argc-1], AccessMode.Read, true);		
					argc -= 2;
				}
			}

			File f = MinFS.open("/binaries/posix", AccessMode.Writable);

			populateChild(arguments[0..argc], child, f, infile.ptr, outfile.ptr);

			yieldToAddressSpace(child);
		}
	}
}

/*bool exists(char[] path, out uint flags) {
	if (streq(path, "/")) {
		flags = Directory.Mode.Directory;
		return true;
	}

	size_t pos = path.length-1;
	foreach_reverse(size_t i, c; path) {
		if (c == '/') {
			pos = i;
			break;
		}
	}
	char[] dirpath = "/";
	if (pos != 0) {
		dirpath = path[0..pos];
	}
	Directory d = Directory.open(dirpath);
	char[] cmpName = path[pos+1..$];
	bool found = false;
	foreach(DirectoryEntry dirent; d) {
		if (streq(cmpName, dirent.name)) {
			// Found the item
			found = true;
			flags = dirent.flags;
			break;
		}
	}
	d.close();
	return found;
}*/

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
