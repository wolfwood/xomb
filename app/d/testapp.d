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
	Console.backcolor = Console.Color.Blue; 
	Console.forecolor = Console.Color.White;
	Console.clear();

	Console.putString("Arrrr, welcome ye to XOmB.\n\n ... ... forgive me ability to rhyme.");

	for (;;) {}
}
