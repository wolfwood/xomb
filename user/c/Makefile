DFLAGS = -I ../../. -I../../runtimes/mindrt -I../../runtimes -O2

syscall.a: mindrt.a
	ldc ${DFLAGS} -c csyscall.d  
	ldc ${DFLAGS} -c ../syscall.d
	ldc ${DFLAGS} -c ../../libos/console.d
	ldc ${DFLAGS} -c ../../libos/fs/minfs.d
	ldc ${DFLAGS} -c ../nativecall.d
	# these belong in mindrt.a
	ldc ${DFLAGS} -c ../../libos/libdeepmajik/threadscheduler.d  ../../libos/libdeepmajik/umm.d ../../runtimes/mindrt/entry.d
	yasm -felf64 pretexttrampoline.S 
	ar rcs lib/libsyscall.a *.o
	#	console.o  csyscall.o entry.o nativecall.o pretexttrampoline.o syscall.o threadscheduler.o umm.o


mindrt.a: clean
	cp ../../runtimes/mindrt/mindrt.a lib/libmindrt.a

clean:
	rm -f lib/*.a
	rm -f *.o
