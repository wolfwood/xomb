/* testapp.d

   Example application to be used with XOmB

*/

module testapp;

import user.syscall;
import user.console;
import user.ramfs;

import libos.console;
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
					uint x,y;
					Console.getPosition(x,y);
					Console.setPosition(x-1,y);
					Console.putChar(' ');
					Console.setPosition(x-1,y);
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
	foreach(size_t i, c; str) {
		if (c == ' ') {
			argument = str[i+1..$];
			str = str[0..i];
		}
	}

	if (streq(str, "clear")) {
		Console.clear();
	}else	if (streq(str, "exit")) {
		exit(0);
	}else	if (streq(str, "test")) {
		ulong va = 40*1024*1024;
		for(int i = 0; i < 32*1024; i++){
			if((i % 1024) == 0){
				Console.putString(".*.");
			}
			allocPage(cast(void*)va);
			char[] arr = cast(char[])(cast(char*)va)[0..4096];
			arr[0] = 'a';
			arr[2] = 'b';
		}
	}	else if (streq(str, "ls")) {
		// Open current directory
		Directory d = Directory.open(workingDirectory);

		// Print current directory
		Console.putString("Listing ");
		Console.putString(workingDirectory);
		Console.putString(":\n");

		Console.putString(".\n");

		// Print items in directory
		foreach(f;d) {
			Console.putString(f);
			Console.putString("\n");
		}
	}
	else if (streq(str, "cd")) {
		// Change directory
		workingDirectory = argument;
	}
	else {
		Console.putString("Unknown Command: ");
		Console.putString(str);
		Console.putString(".\n");
	}
}

char[] workingDirectory = "/";
