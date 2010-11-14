/* xsh.d

   XOmB Native Shell

*/

module hello;

import user.syscall;
import user.ramfs;

import console;

import user.environment;

import libos.libdeepmajik.threadscheduler;

import libos.fs.minfs;

void main() {

	Console.initialize(cast(ubyte*)(2*oneGB));
	Console.backcolor = Color.Black; 
	Console.forecolor = Color.Green;

	MinFS.initialize();

	Console.putString("\nHello, and Welcome to XOmB\n");

	File f = MinFS.open("/foobar", AccessMode.Global);

	Console.putString(  "-=-=-=-=-=-=-=-\n\n");

	//for(;;){}

	Console.backcolor = Color.Black; 
	Console.forecolor = Color.LightGray;

	Console.putString("/foobar starts with: ");
	Console.putString((cast(char[])f)[0..2]);
	Console.putString("\n\n");
}
