LDFLAGS=-L../../../user/c/lib -L../../../runtimes/mindrt  l:drt0.a -l:syscall.a -l:mindrt.a

all:
	x86_64-pc-xomb-gfortran -T../../build/flat.ld -o fhel -static hello.f90 ${LDFLAGS}
	x86_64-pc-xomb-gfortran -T../../../build/elf.ld -o fhel-elf -static hello.f90 ${LDFLAGS}
	cp fhel ../../../build/iso/binaries
