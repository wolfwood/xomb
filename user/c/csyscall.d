module user.c.csyscall;

import Syscall = user.syscall;

import libos.console;

import libos.fs.minfs;

import mindrt.util;

import libos.libdeepmajik.umm;
import Sched = libos.libdeepmajik.threadscheduler;

extern(C):


/* State */
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
bool initFlag = false;


/* Setup */
void initC2D(){
	if(!initFlag){
		MinFS.initialize();

		heapStart = cast(ulong)UserspaceMemoryManager.initHeap().ptr;

		initFlag = true;
	}
}

ulong initHeap(){
	return heapStart;
}


/* Filesystem */
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

int gibOpen(char* name, uint nameLen, bool readOnly, bool append, bool create){
	char[] gibName = cast(char[])name[0..nameLen];

	uint i, fd = -1;

	for(i = 3; i < fdTable.length; i++){
		if(!fdTable[i].valid){
			fd = i;
			break;
		}
	}

	if(fd != -1){
		File foo = MinFS.open(gibName, (readOnly ? AccessMode.Read : AccessMode.Writable) | AccessMode.User, create);
		fdTable[fd].valid = true;

		fdTable[fd].len = cast(ulong*)foo.ptr;

		//  zero file length if writing and not in append mode
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


/* Misc */
void wconsole(char* ptr, int len){

	Console.putString(ptr[0..len]);
}

void perfPoll(int event) {
	return Syscall.perfPoll(event);
}

void exit(ulong val) {
	return Sched.exit(val);
}


/* Directories */

//int mkdir(const char *pathname, mode_t mode)
int mkdir(char *pathname, uint mode){
	// no-op; we don't have directories
	return 0;
}

//int rmdir(const char *pathname)
int rmdir(char *pathname){
	// XXX: delete files with the give prefix
	return 0;
}

//char *getcwd(char *buf, size_t size)
char *getcwd(char *buf, ulong size){
	// XXX: get CWD from key value store in bottle
	char[] name = "/postmark";

	uint len = ((size-1) > name.length) ? name.length : size;

	buf[0..len] = name[0..len];
	buf[len] = '\0';

	return buf;
}