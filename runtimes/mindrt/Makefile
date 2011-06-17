DFLAGS = -I../. -I../../. -O2 -release

drt0.a: entry.d mindrt.a
	yasm -g stabs -felf64 entry.S -o dsss_objs/O/runtime.Sentry.o
	ldc -nodefaultlib -I../../. ${DFLAGS} -c entry.d -ofdsss_objs/O/runtime.entry.o;
	ar rcs drt0.a dsss_objs/O/*.o

mindrt.a: object.d dinvariant.d dstubs.d util.d dstatic.d error.d exception.d
	mkdir -p dsss_imports;
	mkdir -p dsss_objs;
	mkdir -p dsss_objs/G;
	mkdir -p dsss_objs/O;
	mkdir -p dsss_objs/dynamic;
	ldc -nodefaultlib ${DFLAGS} -c object.d -ofdsss_objs/G/runtime.object.o; 
	ldc -nodefaultlib ${DFLAGS} -c ../../user/architecture/mutex.d -ofdsss_objs/G/runtime.mutex.o; 
	ldc -nodefaultlib ${DFLAGS} -c dinvariant.d -ofdsss_objs/G/runtime.dinvariant.o;
	ldc -nodefaultlib ${DFLAGS} -c moduleinit.d -ofdsss_objs/G/runtime.moduleinit.o; 
	ldc -nodefaultlib ${DFLAGS} -c dstubs.d -ofdsss_objs/G/runtime.dstubs.o; 
	ldc -nodefaultlib ${DFLAGS} -c dstatic.d -ofdsss_objs/G/runtime.dstatic.o; 
	ldc -nodefaultlib ${DFLAGS} -c error.d -ofdsss_objs/G/runtime.error.o; 
	ldc -nodefaultlib ${DFLAGS} -c exception.d -ofdsss_objs/G/runtime.exception.o; 
	ldc -nodefaultlib ${DFLAGS} -c array.d -ofdsss_objs/dynamic/runtime.array.o;
	ldc -nodefaultlib ${DFLAGS} -c assocarray.d -ofdsss_objs/dynamic/runtime.assocarray.o;
	ldc -nodefaultlib ${DFLAGS} -c lifetime.d -ofdsss_objs/dynamic/runtime.lifetime.o;
	ldc -nodefaultlib ${DFLAGS} -c gc.d -ofdsss_objs/dynamic/runtime.gc.o;
	ldc -nodefaultlib ${DFLAGS} -I. -c util.d -ofdsss_objs/G/runtime.util.o; 
	ldc -nodefaultlib ${DFLAGS} -c vararg.d -ofdsss_objs/G/runtime.vararg.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_object.d -ofdsss_objs/G/runtime.std.typeinfo.ti_array_object.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_bool.d -ofdsss_objs/G/runtime.std.typeinfo.ti_array_bool.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_char.d -ofdsss_objs/G/runtime.std.typeinfo.ti_array_char.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_wchar.d -ofdsss_objs/G/runtime.std.typeinfo.ti_array_wchar.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_dchar.d -ofdsss_objs/G/runtime.std.typeinfo.ti_array_dchar.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_void.d -ofdsss_objs/G/runtime.std.typeinfo.ti_array_void.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_byte.d -ofdsss_objs/G/runtime.std.typeinfo.ti_array_byte.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_ubyte.d -ofdsss_objs/G/runtime.std.typeinfo.ti_array_ubyte.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_short.d -ofdsss_objs/G/runtime.std.typeinfo.ti_array_short.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_ushort.d -ofdsss_objs/G/runtime.std.typeinfo.ti_array_ushort.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_int.d -ofdsss_objs/G/runtime.std.typeinfo.ti_array_int.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_uint.d -ofdsss_objs/G/runtime.std.typeinfo.ti_array_uint.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_long.d -ofdsss_objs/G/runtime.std.typeinfo.ti_array_long.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_ulong.d -ofdsss_objs/G/runtime.std.typeinfo.ti_array_ulong.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_float.d -ofdsss_objs/G/runtime.std.typeinfo.ti_array_float.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_ifloat.d -ofdsss_objs/G/runtime.std.typeinfo.ti_array_ifloat.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_cfloat.d -ofdsss_objs/G/runtime.std.typeinfo.ti_array_cfloat.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_double.d -ofdsss_objs/G/runtime.std.typeinfo.ti_array_double.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_idouble.d -ofdsss_objs/G/runtime.std.typeinfo.ti_array_idouble.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_cdouble.d -ofdsss_objs/G/runtime.std.typeinfo.ti_array_cdouble.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_real.d -ofdsss_objs/G/runtime.std.typeinfo.ti_array_real.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_ireal.d -ofdsss_objs/G/runtime.std.typeinfo.ti_array_ireal.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_creal.d -ofdsss_objs/G/runtime.std.typeinfo.ti_array_creal.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_object.d -ofdsss_objs/G/runtime.std.typeinfo.ti_object.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_byte.d -ofdsss_objs/G/runtime.std.typeinfo.ti_byte.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_cdouble.d -ofdsss_objs/G/runtime.std.typeinfo.ti_cdouble.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_cfloat.d -ofdsss_objs/G/runtime.std.typeinfo.ti_cfloat.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_char.d -ofdsss_objs/G/runtime.std.typeinfo.ti_char.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_creal.d -ofdsss_objs/G/runtime.std.typeinfo.ti_creal.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_dchar.d -ofdsss_objs/G/runtime.std.typeinfo.ti_dchar.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_delegate.d -ofdsss_objs/G/runtime.std.typeinfo.ti_delegate.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_double.d -ofdsss_objs/G/runtime.std.typeinfo.ti_double.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_float.d -ofdsss_objs/G/runtime.std.typeinfo.ti_float.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_idouble.d -ofdsss_objs/G/runtime.std.typeinfo.ti_idouble.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_ifloat.d -ofdsss_objs/G/runtime.std.typeinfo.ti_ifloat.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_int.d -ofdsss_objs/G/runtime.std.typeinfo.ti_int.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_ireal.d -ofdsss_objs/G/runtime.std.typeinfo.ti_ireal.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_long.d -ofdsss_objs/G/runtime.std.typeinfo.ti_long.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_ptr.d -ofdsss_objs/G/runtime.std.typeinfo.ti_ptr.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_real.d -ofdsss_objs/G/runtime.std.typeinfo.ti_real.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_short.d -ofdsss_objs/G/runtime.std.typeinfo.ti_short.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_ubyte.d -ofdsss_objs/G/runtime.std.typeinfo.ti_ubyte.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_uint.d -ofdsss_objs/G/runtime.std.typeinfo.ti_uint.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_ulong.d -ofdsss_objs/G/runtime.std.typeinfo.ti_ulong.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_ushort.d -ofdsss_objs/G/runtime.std.typeinfo.ti_ushort.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_void.d -ofdsss_objs/G/runtime.std.typeinfo.ti_void.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_wchar.d -ofdsss_objs/G/runtime.std.typeinfo.ti_wchar.o;
	ar rcs mindrt.a dsss_objs/G/*.o

