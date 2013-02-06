DFLAGS = -I../. -I../../. -mattr=-sse -m64 -O2 -release -g

drt0.a: entry.d mindrt.a libd.a objs
	yasm -g stabs -felf64 entry.S -o objs/runtime.Sentry.o
	ldc -nodefaultlib -I../../. ${DFLAGS} -c entry.d -ofobjs/runtime.entry.o;
	ar rcs drt0.a objs/runtime.Sentry.o objs/runtime.entry.o

libd.a: ../libd.d objs
	ldc -nodefaultlib ${DFLAGS} -c ../libd.d -oflibd.o
	ar rcs libd.a libd.o

mindrt.a: object.d dinvariant.d dstubs.d ../util.d dstatic.d error.d exception.d objs
	ldc -nodefaultlib ${DFLAGS} -c entry2.d -ofobjs/runtime.entry2.o;
	ldc -nodefaultlib ${DFLAGS} -c object.d -ofobjs/runtime.object.o;
	ldc -nodefaultlib ${DFLAGS} -c ../../user/architecture/mutex.d -ofobjs/runtime.mutex.o;
	ldc -nodefaultlib ${DFLAGS} -c dinvariant.d -ofobjs/runtime.dinvariant.o;
	ldc -nodefaultlib ${DFLAGS} -c moduleinit.d -ofobjs/runtime.moduleinit.o;
	ldc -nodefaultlib ${DFLAGS} -c dstubs.d -ofobjs/runtime.dstubs.o;
	ldc -nodefaultlib ${DFLAGS} -c dstatic.d -ofobjs/runtime.dstatic.o;
	ldc -nodefaultlib ${DFLAGS} -c error.d -ofobjs/runtime.error.o;
	ldc -nodefaultlib ${DFLAGS} -c exception.d -ofobjs/runtime.exception.o;
	ldc -nodefaultlib ${DFLAGS} -c array.d -ofobjs/dynamic/runtime.array.o;
	ldc -nodefaultlib ${DFLAGS} -c assocarray.d -ofobjs/dynamic/runtime.assocarray.o;
	ldc -nodefaultlib ${DFLAGS} -c lifetime.d -ofobjs/dynamic/runtime.lifetime.o;
	ldc -nodefaultlib ${DFLAGS} -c gc.d -ofobjs/dynamic/runtime.gc.o;
	ldc -nodefaultlib ${DFLAGS} -I. -c ../util.d -ofobjs/runtime.util.o;
	ldc -nodefaultlib ${DFLAGS} -c vararg.d -ofobjs/runtime.vararg.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_object.d -ofobjs/runtime.std.typeinfo.ti_array_object.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_bool.d -ofobjs/runtime.std.typeinfo.ti_array_bool.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_char.d -ofobjs/runtime.std.typeinfo.ti_array_char.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_wchar.d -ofobjs/runtime.std.typeinfo.ti_array_wchar.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_dchar.d -ofobjs/runtime.std.typeinfo.ti_array_dchar.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_void.d -ofobjs/runtime.std.typeinfo.ti_array_void.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_byte.d -ofobjs/runtime.std.typeinfo.ti_array_byte.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_ubyte.d -ofobjs/runtime.std.typeinfo.ti_array_ubyte.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_short.d -ofobjs/runtime.std.typeinfo.ti_array_short.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_ushort.d -ofobjs/runtime.std.typeinfo.ti_array_ushort.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_int.d -ofobjs/runtime.std.typeinfo.ti_array_int.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_uint.d -ofobjs/runtime.std.typeinfo.ti_array_uint.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_long.d -ofobjs/runtime.std.typeinfo.ti_array_long.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_ulong.d -ofobjs/runtime.std.typeinfo.ti_array_ulong.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_float.d -ofobjs/runtime.std.typeinfo.ti_array_float.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_ifloat.d -ofobjs/runtime.std.typeinfo.ti_array_ifloat.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_cfloat.d -ofobjs/runtime.std.typeinfo.ti_array_cfloat.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_double.d -ofobjs/runtime.std.typeinfo.ti_array_double.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_idouble.d -ofobjs/runtime.std.typeinfo.ti_array_idouble.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_cdouble.d -ofobjs/runtime.std.typeinfo.ti_array_cdouble.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_real.d -ofobjs/runtime.std.typeinfo.ti_array_real.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_ireal.d -ofobjs/runtime.std.typeinfo.ti_array_ireal.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_array_creal.d -ofobjs/runtime.std.typeinfo.ti_array_creal.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_object.d -ofobjs/runtime.std.typeinfo.ti_object.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_byte.d -ofobjs/runtime.std.typeinfo.ti_byte.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_cdouble.d -ofobjs/runtime.std.typeinfo.ti_cdouble.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_cfloat.d -ofobjs/runtime.std.typeinfo.ti_cfloat.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_char.d -ofobjs/runtime.std.typeinfo.ti_char.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_creal.d -ofobjs/runtime.std.typeinfo.ti_creal.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_dchar.d -ofobjs/runtime.std.typeinfo.ti_dchar.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_delegate.d -ofobjs/runtime.std.typeinfo.ti_delegate.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_double.d -ofobjs/runtime.std.typeinfo.ti_double.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_float.d -ofobjs/runtime.std.typeinfo.ti_float.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_idouble.d -ofobjs/runtime.std.typeinfo.ti_idouble.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_ifloat.d -ofobjs/runtime.std.typeinfo.ti_ifloat.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_int.d -ofobjs/runtime.std.typeinfo.ti_int.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_ireal.d -ofobjs/runtime.std.typeinfo.ti_ireal.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_long.d -ofobjs/runtime.std.typeinfo.ti_long.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_ptr.d -ofobjs/runtime.std.typeinfo.ti_ptr.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_real.d -ofobjs/runtime.std.typeinfo.ti_real.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_short.d -ofobjs/runtime.std.typeinfo.ti_short.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_ubyte.d -ofobjs/runtime.std.typeinfo.ti_ubyte.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_uint.d -ofobjs/runtime.std.typeinfo.ti_uint.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_ulong.d -ofobjs/runtime.std.typeinfo.ti_ulong.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_ushort.d -ofobjs/runtime.std.typeinfo.ti_ushort.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_void.d -ofobjs/runtime.std.typeinfo.ti_void.o;
	ldc -nodefaultlib ${DFLAGS} -c typeinfo/ti_wchar.d -ofobjs/runtime.std.typeinfo.ti_wchar.o;
	ar rcs mindrt.a objs/*.o

objs:
	mkdir -p objs;
	mkdir -p objs/dynamic;
