module user.c.csyscall;

import Syscalls = user.syscall;

import libos.ramfs;
import libos.console;

extern(C):

bool init = false;


struct fdTableEntry{
	Gib gib;
	bool readOnly;
	bool valid;
}

const uint MAX_NUM_FDS = 128;
fdTableEntry[MAX_NUM_FDS] fdTable;


void wconsole(char* ptr, int len){
	if(!init){
		Console.initialize();
		init=true;
	}

	Console.putString(ptr[0..len]);
}

int gibRead(int fd, ubyte* buf, uint len){
	ubyte[] data = cast(ubyte[])buf[0..len];

	if(!fdTable[fd].valid){
		return -1;
	}

	ubyte[] data2 = data;
	int err = fdTable[fd].gib.read(data2);

	for(uint i = 0; i < err; i++){
		data[i] = data2[i];
	}

	return err;
}

int gibWrite(int fd, ubyte* buf, uint len){
	ubyte[] data = cast(ubyte[])buf[0..len];

	if(!fdTable[fd].valid){
		return -1;
	}

	return fdTable[fd].gib.write(data);
}

int gibOpen(char* name, uint nameLen, bool readOnly){
	char[] gibName = cast(char[])name[0..nameLen];

	uint flags = readOnly ? 1 : 2;

	uint i, fd = -1;
	for(i = 3; i < fdTable.length; i++){
		if(!fdTable[i].valid){
			fd = i;
			break;
		}
	}

	if(fd != -1){
		fdTable[fd].gib = RamFS.open(gibName, flags);
		
		if(fdTable[fd].gib.ptr is null){
			return -1;
		}

		fdTable[fd].valid = true;
		fdTable[fd].readOnly = readOnly;
	}

	return fd;
}

int gibClose(int fd){
	if(fdTable[fd].valid){
		fdTable[fd].gib.close();
		fdTable[fd].valid = false;
		return 0;
	}else{
		return -1;
	}
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
