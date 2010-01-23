module user.c.csyscall;

import Syscalls = user.syscall;

extern(C):

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
