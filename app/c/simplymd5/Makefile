CC = x86_64-pc-xomb-gcc

all: clean
	$(CC) -c simplymd5.c -I../../../user/c/include/.
	$(CC) -o simplymd5 simplymd5.o ../../../user/c/lib/syscall.a ../../../user/c/lib/mindrt.a
	cp simplymd5 ../../../build/iso/boot/.

clean:
	rm -f simplymd5.o simplymd5

