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

void main() {
	for(;;) {
	}

	Console.initialize();
	Console.backcolor = Color.Black; 
	Console.forecolor = Color.Green;

	Console.putString("\nWelcome to XOmB\n");
	Console.putString(  "-=-=-=-=-=-=-=-\n\n");

	Console.backcolor = Color.Black; 
	Console.forecolor = Color.LightGray;

	Console.putString("Done");
}