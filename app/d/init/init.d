/* xsh.d

   XOmB Native Shell

*/

module init;

import embeddedfs;

import Syscall = user.syscall;
import user.ipc;
import user.types;

import console;

import libos.keyboard;
import libos.libdeepmajik.threadscheduler;


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
	AddressSpace xshAS = Syscall.createAddressSpace();

	const char[][] args = ["xsh", "arg"];

	ubyte[] xsh = EmbeddedFS.shell();

	if(xsh !is null){
		populateChild(args, xshAS, xsh);

		XombThread.yieldToAddressSpace(xshAS, 0);
	}

	Console.putString("Done"); for(;;){}
}
