
module kernel.filesystem.ramfs;

import kernel.system.info;
import kernel.core.error;
import kernel.mem.heap;

import kernel.core.kprintf;

import kernel.environ.info;
import kernel.environ.scheduler;

import architecture.vm;

import user.ramfs;

enum Access : uint {
	Create = 1,
	Read = 2,
	Write = 4,
	Append = 8
}

int strcmp(char[] s1, char[] s2) {
	if (s1.length != s2.length) {
		return s1.length - s2.length;
	}

	foreach(uint i, ch; s1) {
		if (s2[i] != ch) {
			return s2[i] - ch;
		}
	}

	return 0;
}

bool streq(char[] s1, uint len, char[] s2) {
	if (len != s2.length) {
		return false;
	}

	foreach(uint i, ch; s2) {
		if (s1[i] != ch) {
			return false;
		}
	}

	return true;
}

bool streq(char[] s1, char[] s2) {
	if (s1.length != s2.length) {
		return false;
	}

	foreach(uint i, ch; s1) {
		if (s2[i] != ch) {
			return false;
		}
	}

	return true;
}
