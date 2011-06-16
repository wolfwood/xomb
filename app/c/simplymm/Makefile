CC = x86_64-pc-xomb-gcc

all: clean
	$(CC) -c simplymm.c -I../../../user/c/include/.
	$(CC) -o simplymm simplymm.o ../../../user/c/lib/syscall.a ../../../runtimes/mindrt/mindrt.a
	cp simplymm ../../../build/root/binaries/.

clean:
	rm -f simplymm.o simplymm

