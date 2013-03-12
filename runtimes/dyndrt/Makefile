DFLAGS = -I../. -I../../. -O2 -release -od=objs -oq -d-version=PlatformXOmB

dyndrt.a: *.d typeinfos/*.d binding/*.d core/*.d data/*.d synch/*.d ../util.d
	mkdir -p objs;
	ldc -nodefaultlib ${DFLAGS} -c ../util.d
	ldc -nodefaultlib ${DFLAGS} -c *.d
	ldc -nodefaultlib ${DFLAGS} -c binding/*.d
	ldc -nodefaultlib ${DFLAGS} -c data/*.d
	ldc -nodefaultlib ${DFLAGS} -c synch/*.d
	# ldc (sometimes) misbehaves unless given these source files one at a time
	find typeinfos/ -name "*.d" -exec ldc -nodefaultlib ${DFLAGS} -c {} \;
	find core/ -name "*.d" -exec ldc -nodefaultlib ${DFLAGS} -c {} \;
	ar rcs $@ objs/*.o

clean:
	rm dyndrt.a
