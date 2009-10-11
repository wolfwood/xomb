syscall.a: mindrt.a
	ldc -c ../syscall.d -I ../../.
	ldc -c ../nativecall.d -I ../../.
	ar rcs lib/syscall.a nativecall.o syscall.o

mindrt.a:
	cp ../../runtimes/mindrt/mindrt.a lib/.
