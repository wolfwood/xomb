/* testapp.d

   Example application to be used with XOmB

*/

module testapp;

import user.syscall;
import user.console;

import libos.console;

void main() {
	long foo = add(5,9);
	asm {
		mov R15, RAX;
	}

	Console.initialize();
	Console.backcolor = Console.Color.Black; 
	Console.forecolor = Console.Color.Green;
	Console.clear();

//	Console.putString("Arrrr, welcome ye to XOmB.\n\n ... ... forgive me ability to rhyme.");
	Console.position((Console.width - 15) / 2, Console.height / 2);
	Console.putString("Welcome to XOmB\n\n");

	for (;;) {}
}
