DFLAGS = -I../. -I../../. -O2 -release -od=dsss_objs/O -oq -d-version=PlatformXOmB

djrt.a: *.d typeinfos/*.d binding/*.d core/*.d data/*.d synch/*.d
	mkdir -p dsss_objs/G;
	mkdir -p dsss_objs/O;
	ldc -nodefaultlib ${DFLAGS} -c *.d
	ldc -nodefaultlib ${DFLAGS} -c typeinfos/*.d
	ldc -nodefaultlib ${DFLAGS} -c binding/*.d core/*.d data/*.d synch/*.d
	ar rcs djrt.a dsss_objs/O/*.o

clean:
	rm djrt.a
