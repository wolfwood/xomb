syscall.a: mindrt.a
	ldc -c csyscall.d -I ../../.
	ldc -c ../syscall.d -I ../../.
	ldc -c ../nativecall.d -I ../../.
	ar rcs lib/syscall.a nativecall.o syscall.o csyscall.o

mindrt.a: clean
	cp ../../runtimes/mindrt/mindrt.a lib/.

clean:
	rm -f lib/*
	rm -f *.o
