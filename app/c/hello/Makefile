LDFLAGS=-L../../../user/c/lib  -lsyscall -lmindrt
all:
	x86_64-pc-xomb-gcc -T../../../user/c/flat.ld -o chel -static hello.c ${LDFLAGS}
	cp chel ../../../build/iso/binaries
