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
	Console.initialize(cast(ubyte*)(2UL*1024UL*1024UL*1024UL));

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
	
	
	for(;;){}
 	

	Console.putString("Done");
}
