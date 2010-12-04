LDFLAGS=-L../../../user/c/lib  -lsyscall -lmindrt

all:
	x86_64-pc-xomb-gfortran -T../../../user/c/flat.ld -o fhel -static hello.f90 ${LDFLAGS}
	x86_64-pc-xomb-gfortran -T../../../user/c/elf.ld -o fhel-elf -static hello.f90 ${LDFLAGS}
	cp fhel ../../../build/iso/binaries
