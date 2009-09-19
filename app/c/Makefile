CC = x86_64-pc-xomb-gcc

all:
	$(CC) -c testapp.c -I../../user/c/include/.
	$(CC) -o testapp testapp.o ../../user/c/syscall.a ../../user/c/mindrt.a

