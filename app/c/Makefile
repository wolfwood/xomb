CC = x86_64-pc-xomb-gcc

all: clean
	$(CC) -c testapp.c -I../../user/c/include/.
	$(CC) -o testapp testapp.o ../../user/c/lib/syscall.a ../../user/c/lib/mindrt.a
	cp testapp ../../build/iso/boot/.

clean:
	rm -f testapp.o testapp

