# ordering is important! drt0 depends on syscall and mindrt, syscall depends on mindrt
#LDFLAGS=-L../../../user/c/lib -L../../../runtimes/mindrt -l:drt0.a -l:syscall.a -l:mindrt.a
all:
	x86_64-pc-xomb-gcc -T../../build/elf.ld -o chel -static hello.c ${LDFLAGS}
	strip -s chel -o ../../../build/root/binaries/chel
