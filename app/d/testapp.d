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
	if (streq(str, "clear")) {
		Console.clear();
	}
	else {
		Console.putString("Unknown Command: ");
		Console.putString(str);
		Console.putString(".\n");
	}
}
