DFLAGS = -I../. -I../../. -O2 -release -od=objs -oq -d-version=PlatformXOmB

dyndrt.a: *.d typeinfos/*.d binding/*.d core/*.d data/*.d synch/*.d ../util.d
	mkdir -p objs;
	ldc -nodefaultlib ${DFLAGS} -c ../util.d
	ldc -nodefaultlib ${DFLAGS} -c *.d
	ldc -nodefaultlib ${DFLAGS} -c typeinfos/*.d
	ldc -nodefaultlib ${DFLAGS} -c binding/*.d core/*.d data/*.d synch/*.d
	ar rcs $@ objs/*.o

clean:
	rm dyndrt.a
