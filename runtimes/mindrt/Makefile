drt0.a: entry.d mindrt.a
	ldc -nodefaultlib -I../../. -I../. -c entry.d -ofdsss_objs/O/runtime.entry.o;
	ar rcs drt0.a dsss_objs/O/*.o

mindrt.a: object.d dinvariant.d dstubs.d util.d dstatic.d error.d exception.d
	mkdir -p dsss_imports;
	mkdir -p dsss_objs;
	mkdir -p dsss_objs/G;
	mkdir -p dsss_objs/O;
	mkdir -p dsss_objs/dynamic;
	ldc -nodefaultlib -I../. -c object.d -ofdsss_objs/G/runtime.object.o; 
	ldc -nodefaultlib -I../. -c dinvariant.d -ofdsss_objs/G/runtime.dinvariant.o;
	ldc -nodefaultlib -I../. -c dstubs.d -ofdsss_objs/G/runtime.dstubs.o; 
	ldc -nodefaultlib -I../. -c dstatic.d -ofdsss_objs/G/runtime.dstatic.o; 
	ldc -nodefaultlib -I../. -c error.d -ofdsss_objs/G/runtime.error.o; 
	ldc -nodefaultlib -I../. -c exception.d -ofdsss_objs/G/runtime.exception.o; 
	ldc -nodefaultlib -I../. -c array.d -ofdsss_objs/dynamic/runtime.array.o;
	ldc -nodefaultlib -I../. -c assocarray.d -ofdsss_objs/dynamic/runtime.assocarray.o;
	ldc -nodefaultlib -I../. -c lifetime.d -ofdsss_objs/dynamic/runtime.lifetime.o;
	ldc -nodefaultlib -I../. -c gc.d -ofdsss_objs/dynamic/runtime.gc.o;
	ldc -nodefaultlib -I../. -I. -c util.d -ofdsss_objs/G/runtime.util.o; 
	ldc -nodefaultlib -I../. -c std/stdarg.d -ofdsss_objs/G/runtime.std.stdarg.o;
	ldc -nodefaultlib -I../. -c std/moduleinit.d -ofdsss_objs/G/runtime.std.moduleinit.o;
	ldc -nodefaultlib -I../. -c typeinfo/ti_AC.d -ofdsss_objs/G/runtime.std.typeinfo.ti_AC.o;
	ldc -nodefaultlib -I../. -c typeinfo/ti_Acdouble.d -ofdsss_objs/G/runtime.std.typeinfo.ti_Acdouble.o;
	ldc -nodefaultlib -I../. -c typeinfo/ti_Acfloat.d -ofdsss_objs/G/runtime.std.typeinfo.ti_Acfloat.o;
	ldc -nodefaultlib -I../. -c typeinfo/ti_Ag.d -ofdsss_objs/G/runtime.std.typeinfo.ti_Ag.o;
	ldc -nodefaultlib -I../. -c typeinfo/ti_Aint.d -ofdsss_objs/G/runtime.std.typeinfo.ti_Aint.o;
	ldc -nodefaultlib -I../. -c typeinfo/ti_Along.d -ofdsss_objs/G/runtime.std.typeinfo.ti_Along.o;
	ldc -nodefaultlib -I../. -c typeinfo/ti_Areal.d -ofdsss_objs/G/runtime.std.typeinfo.ti_Areal.o;
	ldc -nodefaultlib -I../. -c typeinfo/ti_Ashort.d -ofdsss_objs/G/runtime.std.typeinfo.ti_Ashort.o;
	ldc -nodefaultlib -I../. -c typeinfo/ti_C.d -ofdsss_objs/G/runtime.std.typeinfo.ti_C.o;
	ldc -nodefaultlib -I../. -c typeinfo/ti_byte.d -ofdsss_objs/G/runtime.std.typeinfo.ti_byte.o;
	ldc -nodefaultlib -I../. -c typeinfo/ti_cdouble.d -ofdsss_objs/G/runtime.std.typeinfo.ti_cdouble.o;
	ldc -nodefaultlib -I../. -c typeinfo/ti_cfloat.d -ofdsss_objs/G/runtime.std.typeinfo.ti_cfloat.o;
	ldc -nodefaultlib -I../. -c typeinfo/ti_char.d -ofdsss_objs/G/runtime.std.typeinfo.ti_char.o;
	ldc -nodefaultlib -I../. -c typeinfo/ti_creal.d -ofdsss_objs/G/runtime.std.typeinfo.ti_creal.o;
	ldc -nodefaultlib -I../. -c typeinfo/ti_dchar.d -ofdsss_objs/G/runtime.std.typeinfo.ti_dchar.o;
	ldc -nodefaultlib -I../. -c typeinfo/ti_delegate.d -ofdsss_objs/G/runtime.std.typeinfo.ti_delegate.o;
	ldc -nodefaultlib -I../. -c typeinfo/ti_double.d -ofdsss_objs/G/runtime.std.typeinfo.ti_double.o;
	ldc -nodefaultlib -I../. -c typeinfo/ti_float.d -ofdsss_objs/G/runtime.std.typeinfo.ti_float.o;
	ldc -nodefaultlib -I../. -c typeinfo/ti_idouble.d -ofdsss_objs/G/runtime.std.typeinfo.ti_idouble.o;
	ldc -nodefaultlib -I../. -c typeinfo/ti_ifloat.d -ofdsss_objs/G/runtime.std.typeinfo.ti_ifloat.o;
	ldc -nodefaultlib -I../. -c typeinfo/ti_int.d -ofdsss_objs/G/runtime.std.typeinfo.ti_int.o;
	ldc -nodefaultlib -I../. -c typeinfo/ti_ireal.d -ofdsss_objs/G/runtime.std.typeinfo.ti_ireal.o;
	ldc -nodefaultlib -I../. -c typeinfo/ti_long.d -ofdsss_objs/G/runtime.std.typeinfo.ti_long.o;
	ldc -nodefaultlib -I../. -c typeinfo/ti_ptr.d -ofdsss_objs/G/runtime.std.typeinfo.ti_ptr.o;
	ldc -nodefaultlib -I../. -c typeinfo/ti_real.d -ofdsss_objs/G/runtime.std.typeinfo.ti_real.o;
	ldc -nodefaultlib -I../. -c typeinfo/ti_short.d -ofdsss_objs/G/runtime.std.typeinfo.ti_short.o;
	ldc -nodefaultlib -I../. -c typeinfo/ti_ubyte.d -ofdsss_objs/G/runtime.std.typeinfo.ti_ubyte.o;
	ldc -nodefaultlib -I../. -c typeinfo/ti_uint.d -ofdsss_objs/G/runtime.std.typeinfo.ti_uint.o;
	ldc -nodefaultlib -I../. -c typeinfo/ti_ulong.d -ofdsss_objs/G/runtime.std.typeinfo.ti_ulong.o;
	ldc -nodefaultlib -I../. -c typeinfo/ti_ushort.d -ofdsss_objs/G/runtime.std.typeinfo.ti_ushort.o;
	ldc -nodefaultlib -I../. -c typeinfo/ti_void.d -ofdsss_objs/G/runtime.std.typeinfo.ti_void.o;
	ldc -nodefaultlib -I../. -c typeinfo/ti_wchar.d -ofdsss_objs/G/runtime.std.typeinfo.ti_wchar.o;
	ar rcs mindrt.a dsss_objs/G/*.o

