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


void main() {
	MessageInAbottle* bottle = MessageInAbottle.getMyBottle();

	// create heap gib?

	// initialize userspace console code
	if(bottle.stdoutIsTTY){
		Console.initialize(bottle.stdout.ptr);
	}else{
		assert(false);
	}

	if(bottle.stdinIsTTY){
		Keyboard.initialize(cast(ushort*)bottle.stdin.ptr);
	}else{
		assert(false);
	}

	EmbeddedFS.makeFS();

	// say hello
	Console.backcolor = Color.Black; 
	Console.forecolor = Color.Green;

	Console.putString("Y\n");

	foreach(str; bottle.argv){
		Console.putString("X");
		Console.putString(str);
		Console.putString("\n");
	}

	Console.putString("\nWelcome to XOmB\n");
	Console.putString(  "-=-=-=-=-=-=-=-\n\n");
	
	Console.backcolor = Color.Black; 
	Console.forecolor = Color.LightGray;

	// yield to xsh
	AddressSpace xshAS = createAddressSpace();	
	
	map(xshAS, EmbeddedFS.shellAddr(), cast(ubyte*)oneGB, AccessMode.Writable);

	map(xshAS, cast(ubyte*)(2*oneGB), cast(ubyte*)(2*oneGB), AccessMode.Writable);
	map(xshAS, cast(ubyte*)(3*oneGB), cast(ubyte*)(3*oneGB), AccessMode.Writable);

	yieldToAddressSpace(xshAS);

	Console.putString("Done"); for(;;){}
}
