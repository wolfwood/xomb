/* xsh.d

   XOmB Native Shell

*/

module init;

import user.syscall;
import user.ramfs;

import console;
import libos.keyboard;

import user.keycodes;

import libos.libdeepmajik.threadscheduler;

void main() {

	// create heap gib?

	// initialize userspace console code
	Console.initialize(cast(ubyte*)(2UL*1024UL*1024UL*1024UL));
	Keyboard.initialize(cast(ushort*)(3UL*1024UL*1024UL*1024UL));

	// say hello
	Console.backcolor = Color.Black; 
	Console.forecolor = Color.Green;

	Console.putString("\nWelcome to XOmB\n");
	Console.putString(  "-=-=-=-=-=-=-=-\n\n");
	
	Console.backcolor = Color.Black; 
	Console.forecolor = Color.LightGray;

	// initialize userspace keyboard code


	// create new environment

	// load shell module into new gib(s)

	// map gib into new env

	// map in console and keyboard

	// yield to xsh
	
	printPrompt();
	
	char[128] str;
	uint pos = 0;

	bool released;
	for(;;) {
		Key key = Keyboard.nextKey(released);
		//Console.putChar('|');
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


	for(;;){}
 	

	Console.putString("Done");
}

void interpret(char[] str) {
	Console.putString(str);
	Console.putChar('\n');
}

void printPrompt() {
	Console.putString("root@localhost:");
	Console.putString("/");
	Console.putString("$ ");
}
