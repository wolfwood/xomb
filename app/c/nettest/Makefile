LDFLAGS=-I../../../../buildtools/xomb-local/include -L../../../../buildtools/xomb-local/lib -T../../build/elf.ld ../../../../buildtools/xomb-local/lib/libpci.a -g
all:
	# -lpci must come AFTER disktest.c -- LD IS STUPID
	x86_64-pc-xomb-gcc --std=c99 -o nettest -static nettest.c ${LDFLAGS}
	cp nettest ../../../build/root/binaries
