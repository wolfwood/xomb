CC = x86_64-pc-xomb-gcc

all: clean
	$(CC) -c simplyrnd.c -I../../../user/c/include/.
	$(CC) -o simplyrnd simplyrnd.o ../../../user/c/lib/syscall.a ../../../user/c/lib/mindrt.a
	cp simplyrnd ../../../build/iso/boot/.

clean:
	rm -f simplyrnd.o simplyrnd

