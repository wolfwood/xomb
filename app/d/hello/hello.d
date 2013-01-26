/* xsh.d

   XOmB Native Shell

*/

module hello;

import console;

// requied by entry.
import libos.keyboard;
import libos.libdeepmajik.threadscheduler;

// why is this required?
import libos.fs.minfs;

void main(char[][] argv) {
	Console.backcolor = Color.Black;
	Console.forecolor = Color.Green;

	Console.putString("\nHello, and Welcome to XOmB\n");
	Console.putString(  "-=-=-=-=-=-=-=-\n\n");

	Console.backcolor = Color.Black;
	Console.forecolor = Color.LightGray;

	foreach(str; argv){
		Console.putString(str);
		Console.putString("\n");
	}

	Console.putString("\n");
}
