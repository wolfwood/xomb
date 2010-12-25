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

	map(xshAS, EmbeddedFS.shellAddr(), cast(ubyte*)oneGB, AccessMode.Writable);


	MessageInAbottle* childBottle = MessageInAbottle.getBottleForSegment(EmbeddedFS.shellAddr());

	// XXX: use findFreeSemgent to pick gib locations in child
	childBottle.stdout = (cast(ubyte*)(2*oneGB))[0..oneGB];
	childBottle.stdoutIsTTY = true;
	childBottle.stdin = (cast(ubyte*)(3*oneGB))[0..oneGB];
	childBottle.stdinIsTTY = true;

	map(xshAS, bottle.stdout.ptr, childBottle.stdout.ptr, AccessMode.Writable);
	map(xshAS, bottle.stdin.ptr, childBottle.stdin.ptr, AccessMode.Writable);
	

	yieldToAddressSpace(xshAS);

	Console.putString("Done"); for(;;){}
}
