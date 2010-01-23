CC = x86_64-pc-xomb-gcc

all: clean
	$(CC) -c simplymm.c -I../../../user/c/include/.
	$(CC) -o simplymm simplymm.o ../../../user/c/lib/syscall.a ../../../user/c/lib/mindrt.a
	cp simplymm ../../../build/iso/boot/.

clean:
	rm -f simplymm.o simplymm

