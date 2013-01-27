DFLAGS = -I ../../. -I../../runtimes/mindrt -I../../runtimes -mattr=-sse -m64 -O2 -release -g  -oq -odobjs

syscall.a: clean
	mkdir -p objs
	ldc ${DFLAGS} -c cbindings.d
	ldc ${DFLAGS} -c ../syscall.d
	ldc ${DFLAGS} -c ../../libos/console.d
	ldc ${DFLAGS} -c ../../libos/fs/minfs.d
	ldc ${DFLAGS} -c ../nativecall.d
	# these meet dependencies of drt0.a
	ldc ${DFLAGS} -c ../../libos/libdeepmajik/threadscheduler.d  ../../libos/libdeepmajik/umm.d ../../user/environment.d ../../user/ipc.d ../../libos/keyboard.d
	mkdir -p lib
	ar rcs lib/cbindings.a objs/*.o
	#	console.o  csyscall.o entry.o nativecall.o pretexttrampoline.o syscall.o threadscheduler.o umm.o

clean:
	rm -f lib/*.a
	rm -f objs/*.o
