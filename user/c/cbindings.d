module user.c.cbindings;

import Syscall = user.syscall;

import libos.console;

import libos.fs.minfs;

import util;

import libos.libdeepmajik.umm;
import Sched = libos.libdeepmajik.threadscheduler;
import user.environment;
import user.ipc;

import user.c.c;

extern(C) int errno;


/* State */
struct fdTableEntry{
	ulong* len;
	ubyte* data;
	ulong pos;
	bool readOnly;
	bool valid;
	bool device;
	long posoffset;

	bool dir;
}

const uint MAX_NUM_FDS = 128;
fdTableEntry[MAX_NUM_FDS] fdTable;

ulong heapStart;
bool initFlag = false;


extern(C):
// first, the 13 required calls

// --- Process Control ---

void _exit(ulong val) {
	return Sched.exit(val);
}

int _execve(char *name, char **argv, char **env) {
	logError("EXEC!\n");

	errno = C.Errno.ENOMEM;
	return -1;
}


int fork() {
	logError("FORK!\n");

	errno = C.Errno.ENOTSUP;
	return -1;
}

int getpid()
{
	ulong physAddr;
	PageLevel!(1)* levelOfSegment;

	root.walk!(getPid)(cast(AddressFragment)createAddress(510,510,510,510), physAddr, levelOfSegment);

	return physAddr;
}

int kill(int pid, int sig){
  if(pid == getpid())
    _exit(sig);

	logError("KILL!\n");

	errno = C.Errno.EINVAL;
  return -1;
}

int wait(int *status) {
	logError("WAIT!\n");

	errno = C.Errno.ECHILD;
	return -1;
}


// --- I/O ---

int _isatty(int fd){
	if(fdTable[fd].valid){
		if(fdTable[fd].device){
			return 1;
		}else{
			return 0;
		}
	}else{
		errno = C.Errno.EBADF;
		return -1;
	}
}

int open(char *name, C.Mode flags, ...) {
	int nameLen = strlen(name);
	bool readOnly = true,  append, create, trunc;
	int fd;

	// O_RDONLY isn't Quite a flag, is defined as 0
	if(flags & C.Mode.O_ACCMODE){
		readOnly = false;
	}

	if(flags & C.Mode.O_CREAT){
		create = true;
	}

	if(flags & C.Mode.O_APPEND){
		append = true;
	}

	if(flags & C.Mode.O_TRUNC){
		trunc = true;
	}

	fd = gibOpen(name, nameLen, readOnly, append, create, trunc);

	if(fd == -1){
		return -1;
	}

	return fd;
}

int
close(int file) {
	int err = gibClose(file);

	if(err < 0){
		errno = C.Errno.EBADF;
		return -1;
	}else{
		return 0;
	}
}

int
read(int file, ubyte* ptr, uint len) {
	// XXX: keyboard support
	if(fdTable[file].device){
		return -1;
	}

	int err = gibRead(file, ptr, len);

	if(err == -1){
		errno = C.Errno.EBADF;
	}

	return err;
}

int
write(int file, ubyte* ptr, uint len) {
	if(fdTable[file].valid && !fdTable[file].readOnly){
		if(fdTable[file].device){
			wconsole(cast(char*)ptr, len);

			return len;
		}

		return gibWrite(file, ptr, len);
	}else{
		errno = C.Errno.EBADF;
		return -1;
	}
}

/* XXX: implement these */
int lseek(int file, C.off_t ptr, C.Whence dir) {
	logError("LSEEK!\n");

	if(!fdTable[file].valid){
		errno = C.Errno.EBADF;
		return -1;
	}

	int posfd = file + fdTable[file].posoffset;

	switch(dir){
	case C.Whence.SEEK_SET:
		fdTable[posfd].pos = ptr;
		break;
	case C.Whence.SEEK_CUR:
		fdTable[posfd].pos += ptr;
		break;
	case C.Whence.SEEK_END:
		fdTable[posfd].pos = *fdTable[file].len + ptr;
		break;

		//XXX: SEEK_DATA SEEK_HOLE
	}

	return 	fdTable[posfd].pos;
}


int fstat(int file, C.stat *st) {
	if(fdTable[file].valid){
		st.st_mode = C.mode_t.init;

		if(fdTable[file].device){
			st.st_mode = C.mode_t.S_IFCHR|C.mode_t.ACCESSPERMS;
		}else if(fdTable[file].dir){
			st.st_mode = C.mode_t.S_IFDIR|C.mode_t.ACCESSPERMS;
		}else{
			st.st_mode = C.mode_t.S_IFREG|C.mode_t.ACCESSPERMS;

			if(fdTable[file].len is null){
				logError("null len\n");
				for(int i = 0; i <= file; i++){
					logError("F");
				}

				errno = C.Errno.EBADF;
				return -1;
				logError("FSTAT on file with null length pointer!\n");
			}

			//st.st_ino = cast((fdTable[fd].data);
			st.st_size = *(fdTable[file].len);

			st.st_blocks = ((*fdTable[file].len) / 512) + (((*fdTable[file].len)%512) == 0 ? 0 : 1);
		}

		return 0;
	}else{
		errno = C.Errno.EBADF;
		return -1;
	}
}

int stat(char *file, C.stat *st){
	int fd = open(file, C.Mode.O_RDONLY);

	if(fd >= 0){
		return fstat(fd, st);
	}

	return fd;
}

int
link(char *old, char *newlink) {
	logError("LINK!\n");

	errno = C.Errno.EMLINK;
	return -1;
}

int
unlink(char *name) {
	logError("UNLINK!\n");

	errno = C.Errno.ENOENT;
	return -1;
}


// some additional functions that aren't provided by default

// missing binutils deps: fnctl, umask, chmod, access, lstat, pathconf, utime

int fcntl(int fd, int cmd, ... ){
	logError("FCNTL!\n");

	errno = C.Errno.ENOSYS;
  return -1;
}

C.mode_t umask(C.mode_t mask){
	logError("UMASK!\n");

	return C.mode_t.ACCESSPERMS;
}

int chmod(char *path, C.mode_t mode){
	logError("CHMOD!\n");
	errno = C.Errno.ENOSYS;
  return -1;
}

int chown(char *path, C.uid_t owner, C.gid_t group){
	logError("CHOWN!\n");

	errno = C.Errno.ENOSYS;
  return -1;
}

int access(char *pathname, int mode){
	logError("ACCESS!\n");

	return 0;
}

int lstat(char *path, C.stat *buf){
	logError("LSTAT!\n");

	return stat(path, buf);
}

long pathconf(char *path, int name){
	logError("PATHCONF!\n");

	// no limits
	return -1;
}

// missing gcc deps: sleep, alarm, pipe, dup2, execvp

uint sleep(uint seconds){
	logError("SLEEP!\n");

	return 0;
}

uint alarm(uint seconds){
	logError("alarm!\n");

	return 0;
}

int pipe(int pipefd[2]){
	logError("PIPE!\n");

	return fail();
}

int dup(int oldfd){
	logError("DUP!\n");
	// XXX: find a free fd
	return dup2(oldfd, 7);
}

int dup2(int oldfd, int newfd){
	logError("DUP2!\n");
	return fail();
}

long sysconf(int name){
	logError("SYSCONF!\n");
	return fail();
}

int chdir(char *path){
	logError("CHDIR!\n");

	return fail();
}

int fail(){
	errno = C.Errno.ENOSYS;
  return -1;
}

/* Directories */

//int mkdir(const char *pathname, mode_t mode)
int mkdir(char *pathname, uint mode){
	logError("MKDIR!\n");

	// no-op; we don't have directories
	return 0;
}

//int rmdir(const char *pathname)
int rmdir(char *pathname){
	logError("RMDIR!\n");

	// XXX: delete files with the give prefix
	return 0;
}

//char *getcwd(char *buf, size_t size)
char *getwd(char *buf){
	logError("GETWD\n");

	// XXX: get CWD from key value store in bottle
	char[] name = "/postmark";

	uint len = name.length;

	buf[0..len] = name[0..len];
	buf[len] = '\0';

	return buf;
}


/* --- for PRIVILEGED drivers --- */
ubyte* mapdev(PhysicalAddress phys, ulong size){
	ubyte[] gib = findFreeSegment(false, size);

	Syscall.makeDeviceGib(gib.ptr, phys, size);

	return gib.ptr;
}


PhysicalAddress virt2phys(ubyte* virtAddy){
	ulong bits = cast(ulong)virtAddy & 0xFFF;
	return cast(PhysicalAddress)(cast(ulong)getPhysicalAddressOfPage(virtAddy) | bits);
}

/* --- Old --- */

/* Setup */
void initC2D(){
	if(!initFlag){
		MinFS.initialize();

		heapStart = cast(ulong)UserspaceMemoryManager.initHeap().ptr;

		initFlag = true;

		MessageInAbottle* bottle = MessageInAbottle.getMyBottle();

		fdTable[0].valid = true;
		fdTable[0].readOnly = true;

		if(bottle.stdinIsTTY){
			fdTable[0].device = true;
		}else{
			fdTable[0].len = cast(ulong*)bottle.stdin;
			fdTable[0].data = bottle.stdin.ptr + ulong.sizeof;
		}


		fdTable[1].valid = true;
		fdTable[2].valid = true;

		if(bottle.stdoutIsTTY){
			fdTable[1].device = true;
			fdTable[2].device = true;
		}else{
			fdTable[1].len = cast(ulong*)bottle.stdout;
			fdTable[1].data = bottle.stdout.ptr + ulong.sizeof;

			fdTable[2].len = cast(ulong*)bottle.stdout;
			fdTable[2].data = bottle.stdout.ptr + ulong.sizeof;
			fdTable[2].posoffset = -1;
		}
	}
}

/* Misc */
void wconsole(char* ptr, int len){

	Console.putString(ptr[0..len]);
}

void perfPoll(int event) {
	return Syscall.perfPoll(event);
}

ulong initHeap(){
	return heapStart;
}


extern(D):
bool getPid(T,U)(T table, uint idx, ref ulong physAddr, ref U levelOfSegment){
	if(table.entries[idx].present){
		static if(is(T == U)){
			physAddr = table.entries[idx].address; // >> 12
			return false;
		}else{
			return true;
		}
	}
	return false;
}

private:
/* Filesystem */
int gibRead(int fd, ubyte* buf, uint len){
	if(!fdTable[fd].valid){
		return -1;
	}

	int posfd = fd + fdTable[fd].posoffset;

	if((fdTable[posfd].pos + len) > *(fdTable[fd].len)){
		len = *(fdTable[fd].len) - fdTable[posfd].pos;
	}

	memcpy(buf, fdTable[fd].data + fdTable[posfd].pos, len);
	fdTable[posfd].pos += len;

	return len;
}

void logError(char[] err){
	write(2, cast(ubyte*)err.ptr, err.length);
}

void logUlong(ulong val){
	logError("0x");

	for(int i = 15; i >= 0; i--){
		char[1] alpha;
		ubyte tmp = ((val >> (i*4)) & 0xF);

		if(tmp < 10){
			alpha[0] = cast(char)('0' + tmp);
		}else if(tmp < 16){
			alpha[0] = cast(char)('a' + tmp);
		}

		logError(alpha);
	}

}

int gibWrite(int fd, ubyte* buf, uint len){
	int posfd = fd + fdTable[fd].posoffset;

	if((fdTable[posfd].pos + len) > *(fdTable[fd].len)){
		// XXX: lockfree
		*(fdTable[fd].len) = len + fdTable[posfd].pos;
	}

	memcpy(fdTable[fd].data + fdTable[posfd].pos, buf, len);
	fdTable[posfd].pos += len;

	return len;
}

int gibOpen(char* name, uint nameLen, bool readOnly, bool append, bool create, bool trunc){
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

		if(!create && foo is null){
			errno = C.Errno.ENOENT;
			return -1;
		}

		if(foo is null){
			errno = C.Errno.ENOMEM;
			return -1;
		}

		if(gibName[$-1 .. $] == "/"){
			fdTable[fd].dir = true;
		}


		fdTable[fd] = fdTableEntry.init;
		fdTable[fd].valid = true;

		fdTable[fd].len = cast(ulong*)foo.ptr;

		if(trunc){
			*fdTable[fd].len = 0;
		}

		fdTable[fd].data = foo.ptr + ulong.sizeof;
		fdTable[fd].pos = 0;

		//fdTable[fd].data = ;
	}else{
		errno = C.Errno.EMFILE;
	}

	return fd;
}

int gibClose(int fd){
	fdTable[fd] = fdTableEntry.init;
	fdTable[fd].valid = false;
	return 0;
}
