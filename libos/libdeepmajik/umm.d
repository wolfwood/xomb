module libos.libdeepmajik.umm;

import user.syscall;

extern ubyte _end;


ubyte* pageStack = cast(ubyte*)0x1000_0000UL;


ubyte* getPage(bool spacer = false){
	pageStack -= 4096;
	
	ubyte* temp = pageStack;

	allocPage(cast(ubyte*)pageStack);
	
	if(spacer){pageStack -= 4096;}

	return temp;
}

void freePage(ubyte* page){
	// XXX: Actually Free Page
	return;
}