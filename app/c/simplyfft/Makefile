CC = x86_64-pc-xomb-gcc

all: clean
	$(CC) -c simplyfft.c -I../../../user/c/include/.
	$(CC) -o simplyfft simplyfft.o ../../../user/c/lib/syscall.a ../../../user/c/lib/mindrt.a
	cp simplyfft ../../../build/iso/boot/.

clean:
	rm -f simplyfft.o simplyfft

