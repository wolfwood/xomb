all:
	x86_64-pc-xomb-gcc -T../../../user/c/flat.ld -o chel -static hello.c ../../../user/c/*.o ../../../user/c/lib/mindrt.a
	cp chel ../../../build/iso/binaries
