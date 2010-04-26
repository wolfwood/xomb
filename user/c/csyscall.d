module user.c.csyscall;

import Syscalls = user.syscall;

import libos.ramfs;
import libos.console;

extern(C):

bool init = false;

void wconsole(char* ptr, int len){
	/*if(!init){
		Console.initialize();
		init=true;
	}

	Console.putString(ptr[0..len]);*/
	//Syscalls.dispUlong(len);
	Syscalls.log(cast(char[])ptr[0..len]);
}

int gibRead(Gib* gib, ubyte* buf, uint len){
	ubyte[] data = cast(ubyte[])buf[0..len];

	return gib.read(data);
}

int gibWrite(Gib* gib, ubyte* buf, uint len){
	ubyte[] data = cast(ubyte[])buf[0..len];

	return gib.write(data);
}

ubyte* gibOpen(char* name, uint nameLen, bool readOnly){
	char[] gibName = cast(char[])name[0..nameLen];

	uint flags = readOnly ? 1 : 2;

	return RamFS.open(gibName, flags).ptr;
}

int allocPage(void* virtAddr) {
	return Syscalls.allocPage(virtAddr);
}

void perfPoll(int event) {
	return Syscalls.perfPoll(event);
}

void exit(int val) {
	return Syscalls.exit(val);
}

int add(int a, int b) {
	return Syscalls.add(a,b);
}
