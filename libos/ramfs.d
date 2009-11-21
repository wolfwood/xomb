
module libos.ramfs;

import user.ramfs;
import user.syscall;

extern(C) void* memcpy(void*, void*, size_t);


struct FD{
	Inode* inode;
	ulong offset;
}

FD[256] fdtable;

// open
int Open(char[] path, int flags, int mode){

	// XXX: not the least bit threadsafe... this is bad
	for(uint i = 3; i < fdtable.length; i++){
		if(fdtable[i].inode is null){
			int err = open(path, &fdtable[i].inode);

			if(err != SyscallError.OK){
				return -1;
			}else{
				return i;
			}
		}
	}
	
	return -1; // XXX: EMFILE
}

// close
int close(int f){
	if(fdtable[f].inode is null){
		return -1;
	}else{
		fdtable[f].offset = 0;
		fdtable[f].inode  = null;

		//XXX: Close syscall...

		return 0;
	}
}

// read
int read(int file, char[] ptr, int len) {
	assert(fdtable[file].inode !is null);

	if(fdtable[file].inode.length < (fdtable[file].offset + len)){
		len = fdtable[file].inode.length - fdtable[file].offset;
	}

	if(fdtable[file].inode.isContiguous){

		memcpy(cast(void*)(cast(ulong)fdtable[file].inode.directPtrs[0] + fdtable[file].offset), 
					 ptr.ptr, len);

		return len;
	}else{
		// XXX: implement inode traversal and copying in 4k chunks

		return -1;
	}
}

// write
/*
int
write(int file, char *ptr, int len) {
        //XXX: write to stdout

        return -1;
}

*/

enum Whence { SEEK_SET = 0, SEEK_CUR = 1, SEEK_END = 2}

// lseek
int lseek(int file, int ptr, int dir) {
	assert(fdtable[file].inode !is null);

	// XXX guard against overflowing file length
  switch(cast(Whence)dir){
	case Whence.SEEK_SET:
		fdtable[file].offset = ptr;
		break;
	case Whence.SEEK_CUR:
		fdtable[file].offset += ptr;
		break;
	case Whence.SEEK_END:
		fdtable[file].offset = fdtable[file].inode.length - ptr;
		break;
	}
	
	return 0;
}

// link
/*
int
link(char *old, char *new) {
        errno = EMLINK;
        return -1;
}
*/

// unlink
/*
int
unlink(char *name) {
        errno = ENOENT;
        return -1;
}
*/

// stat
/*
int 
stat(int file, struct stat *st) {
        st->st_mode = S_IFCHR;
        return 0;
}
*/

//istty

/*int
isatty(fd)
     int fd;
{
  return (1);
	}*/

