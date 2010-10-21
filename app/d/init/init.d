/* xsh.d

   XOmB Native Shell

*/

module init;

import user.syscall;
import user.ramfs;

import console;

import libos.ramfs;
import libos.keyboard;

import user.keycodes;

import libos.libdeepmajik.threadscheduler;

void main() {
	// create heap gib?

	// initialize userspace console code

	// initialize userspace keyboard code

	// say hello

	// create new environment

	// load shell module into new gib(s)

	// map gib into new env

	// map in console and keyboard

	// yield to xsh
	
	

	/*Console.initialize();
	Console.backcolor = Color.Black; 
	Console.forecolor = Color.Green;

	Console.putString("\nWelcome to XOmB\n");
	Console.putString(  "-=-=-=-=-=-=-=-\n\n");

	Console.backcolor = Color.Black; 
	Console.forecolor = Color.LightGray;

	Console.putString("Done");*/
}
