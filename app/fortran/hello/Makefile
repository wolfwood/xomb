all:
	x86_64-pc-xomb-gfortran -T../../../user/c/flat.ld -o fhel -static hello.f90 ../../../user/c/*.o ../../../user/c/lib/mindrt.a
	x86_64-pc-xomb-gfortran -T../../../user/c/elf.ld -o fhel-elf -static hello.f90 ../../../user/c/*.o ../../../user/c/lib/mindrt.a
	cp fhel ../../../build/iso/binaries
