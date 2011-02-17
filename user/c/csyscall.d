module user.c.csyscall;

import Syscalls = user.syscall;
import libos.console;

import libos.fs.minfs;

import mindrt.util;

import Umm = libos.libdeepmajik.umm;

extern(C):

bool initFlag = false;


struct fdTableEntry{
	ulong* len;
	ubyte* data;
	ulong pos;
	bool readOnly;
	bool valid;
}

const uint MAX_NUM_FDS = 128;
fdTableEntry[MAX_NUM_FDS] fdTable;

ulong heapStart;

void initC2D(){
	if(!initFlag){
		MinFS.initialize();

		heapStart = cast(ulong)Umm.initHeap().ptr;

		initFlag = true;
	}
}

int gibRead(int fd, ubyte* buf, uint len){
	if(!fdTable[fd].valid){
		return -1;
	}

	if((fdTable[fd].pos + len) > *(fdTable[fd].len)){
		len = *(fdTable[fd].len) - fdTable[fd].pos;
	}

	memcpy(buf, fdTable[fd].data + fdTable[fd].pos, len);
	fdTable[fd].pos += len;

	return len;
}

int gibWrite(int fd, ubyte* buf, uint len){
	if(!fdTable[fd].valid){
		return -1;
	}

	if((fdTable[fd].pos + len) > *(fdTable[fd].len)){
		// XXX: lockfree 
		*(fdTable[fd].len) = len + fdTable[fd].pos;
	}

	memcpy(fdTable[fd].data + fdTable[fd].pos, buf, len);
	fdTable[fd].pos += len;

	return len;
}

int gibOpen(char* name, uint nameLen, bool readOnly, bool append = false){
	char[] gibName = cast(char[])name[0..nameLen];

	uint i, fd = -1;

	for(i = 3; i < fdTable.length; i++){
		if(!fdTable[i].valid){
			fd = i;
			break;
		}
	}

	if(fd != -1){
		File foo = MinFS.open(gibName, (readOnly ? AccessMode.Read : AccessMode.Writable));
		fdTable[fd].valid = true;

		fdTable[fd].len = cast(ulong*)foo.ptr;

		//  append mode
		if(!readOnly && !append){
			*fdTable[fd].len = 0;
		}

		fdTable[fd].data = foo.ptr + ulong.sizeof;
		fdTable[fd].pos = 0;
	}

	return fd;
}


int gibClose(int fd){
	return 0;
}

void wconsole(char* ptr, int len){

	Console.putString(ptr[0..len]);
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

ulong initHeap(){
	return heapStart;
}