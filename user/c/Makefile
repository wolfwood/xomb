DFLAGS = -I ../../. -I../../runtimes/mindrt -I../../runtimes

syscall.a: mindrt.a
	ldc ${DFLAGS} -c csyscall.d  
	ldc ${DFLAGS} -c ../syscall.d
	ldc ${DFLAGS} -c ../../libos/console.d
	ldc ${DFLAGS} -c ../../libos/fs/minfs.d
	ldc ${DFLAGS} -c ../nativecall.d
	# these belong in mindrt.a
	ldc ${DFLAGS} -c ../../runtimes/mindrt/entry.d ../../libos/libdeepmajik/threadscheduler.d  ../../libos/libdeepmajik/umm.d
	yasm -felf64 pretexttrampoline.S 
	ar rcs lib/syscall.a *.o
	#	console.o  csyscall.o entry.o nativecall.o pretexttrampoline.o syscall.o threadscheduler.o umm.o


mindrt.a: clean
	cp ../../runtimes/mindrt/mindrt.a lib/.

clean:
	rm -f lib/*
	rm -f *.o
