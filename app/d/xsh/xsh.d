/* xsh.d

   XOmB Native Shell

*/

module xsh;

import Syscall = user.syscall;

import console;
import libos.keyboard;
import user.keycodes;

import libos.libdeepmajik.threadscheduler;

import libos.fs.minfs;
import user.ipc;


void main() {
	Console.backcolor = Color.Black;
	Console.forecolor = Color.Green;

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
	else if (streq(cmd, "pwd")) {
		// Print working directory
		Console.putString(workingDirectory);
		Console.putString("\n");
	}
	else if (streq(cmd, "run")) {
		// Open the file, parse the ELF into a new address space, and execute

		if (argument.length > 0) {
			createArgumentPath(arguments[1]);

			AddressSpace child = Syscall.createAddressSpace();

			File f = MinFS.open(argumentPath, AccessMode.User|AccessMode.Writable|AccessMode.Executable);

			if(f is null){Console.putString("Binary Not Found!\n"); return;}

			// trim path of or binary name for argv[0]
			int i = 0;
			foreach(j, ch; arguments[1]){
				if(ch == '/'){
					i = j;
				}
			}
			arguments[1] = arguments[1][(i+1)..$];


			populateChild(arguments[1..argc], child, f);

			XombThread.yieldToAddressSpace(child,0);
		}
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
		if (str.length > 0) {
			AddressSpace child = Syscall.createAddressSpace();
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

			char[64] pathNameStorage;
			char[] pathName = pathNameStorage;
			pathName[0..10] = "/binaries/";

			uint pathNameLength = 10;

			bool fallback = true;
			File f;

			uint idx;

			if(arguments[0][0] != '/'){
				uint len = arguments[0].length < pathName.length - pathNameLength ? arguments[0].length : pathName.length - pathNameLength;
				char[] testPathName = pathName[0..(pathNameLength+len)];

				testPathName[pathNameLength..(pathNameLength+len)] = arguments[0];

				if(testPathName == MinFS.findPrefix(testPathName, idx)){
					f = MinFS.open(testPathName, AccessMode.User|AccessMode.Writable|AccessMode.Executable);
					fallback = false;
				}
			}
			else {
				if(arguments[0] == MinFS.findPrefix(arguments[0], idx)){
					f = MinFS.open(arguments[0], AccessMode.User|AccessMode.Writable|AccessMode.Executable);
					fallback = false;
				}
			}

			if(fallback){
				f = MinFS.open("/binaries/posix", AccessMode.User|AccessMode.Writable|AccessMode.Executable);
			}

			assert(f !is null);

			populateChild(arguments[0..argc], child, f, infile, outfile);

			XombThread.yieldToAddressSpace(child,0);
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
