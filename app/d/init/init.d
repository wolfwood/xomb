/* xsh.d

   XOmB Native Shell

*/

module init;

import embeddedfs;

import user.syscall;
import user.environment;

import libos.fs.minfs;

import console;
import libos.keyboard;

import user.keycodes;

import libos.libdeepmajik.threadscheduler;

import libos.elf.loader;
import mindrt.util;


void main(char[][] argv) {
	MessageInAbottle* bottle = MessageInAbottle.getMyBottle();

	// create heap gib?

	EmbeddedFS.makeFS();

	// say hello
	Console.backcolor = Color.Black; 
	Console.forecolor = Color.Green;

	Console.putString("\nWelcome to XOmB\n");
	Console.putString(  "-=-=-=-=-=-=-=-\n\n");
	
	Console.backcolor = Color.Black; 
	Console.forecolor = Color.LightGray;

	// yield to xsh
	AddressSpace xshAS = createAddressSpace();	

	const char[][] args = ["xsh", "arg"];

	populateForegroundChild(args, xshAS, EmbeddedFS.shell());

	yieldToAddressSpace(xshAS);

	Console.putString("Done"); for(;;){}
}
