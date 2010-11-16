/* xsh.d

   XOmB Native Shell

*/

module init;

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

	// create heap gib?

	// initialize userspace console code
	Console.initialize(cast(ubyte*)(2*oneGB));
	Keyboard.initialize(cast(ushort*)(3*oneGB));

	MinFS.format();

	// say hello
	Console.backcolor = Color.Black; 
	Console.forecolor = Color.Green;

	Console.putString("\nWelcome to XOmB\n");
	Console.putString(  "-=-=-=-=-=-=-=-\n\n");
	
	Console.backcolor = Color.Black; 
	Console.forecolor = Color.LightGray;

	makeFS!("binaries/hello", true)();
	File xsh = makeFS!("binaries/xsh", true)();
	makeFS!("kernel/LICENSE", false)();
	
	// yield to xsh
	Console.putString("Create\n");
	AddressSpace xshAS = createAddressSpace();	
	Console.putString("Load\n");
	
	map(xshAS, xsh.ptr, cast(ubyte*)oneGB, AccessMode.Writable);

	Console.putString("Map\n");
	map(xshAS, cast(ubyte*)(2*oneGB), cast(ubyte*)(2*oneGB), AccessMode.Writable);
	map(xshAS, cast(ubyte*)(3*oneGB), cast(ubyte*)(3*oneGB), AccessMode.Writable);

	Console.putString("Yield\n");

	yieldToAddressSpace(xshAS);


	Console.putString("Done"); for(;;){}
}

template makeFS(char[] filename, bool exe){
	File makeFS(){
		const char[] actualFilename = "/" ~ filename;

		// import file
		ubyte[] data = cast(ubyte[])import(filename);

		// create minFS file
		File f =  MinFS.open(actualFilename, AccessMode.Writable);

		// populate
		if(exe){
			memcpy(cast(void*)f.ptr, cast(void*)data.ptr, data.length);
		}else{
			ulong* size = cast(ulong*)f.ptr;

			*size = data.length;

			memcpy(cast(void*)((f.ptr)[ulong.sizeof..ulong.sizeof]).ptr, cast(void*)data.ptr, data.length);
		}

		return f;
	}
}

