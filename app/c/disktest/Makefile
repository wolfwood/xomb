LDFLAGS=-I../../../../buildtools/xomb-local/include -L../../../../buildtools/xomb-local/lib -T../../build/elf.ld ../../../../buildtools/xomb-local/lib/libpci.a
all:
	# -lpci must come AFTER disktest.c -- LD IS STUPID
	x86_64-pc-xomb-gcc --std=c99 -o disktest -static disktest.c ${LDFLAGS}
	cp disktest ../../../build/root/binaries
