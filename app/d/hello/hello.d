/* xsh.d

   XOmB Native Shell

*/

module hello;

import user.syscall;

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
	Console.putString(  "-=-=-=-=-=-=-=-\n\n");

	Console.backcolor = Color.Black; 
	Console.forecolor = Color.LightGray;
}
