drt0.a: entry.d mindrt.a
	ldc -nodefaultlib -I../../. -Imindrt/. -c entry.d -ofdsss_objs/O/runtime.entry.o;
	ar rcs drt0.a dsss_objs/O/*.o

mindrt.a: object.d invariant.d dstubs.d util.d
	mkdir -p dsss_imports;
	mkdir -p dsss_objs;
	mkdir -p dsss_objs/G;
	mkdir -p dsss_objs/O;
	ldc -nodefaultlib -Imindrt/. -c object.d -ofdsss_objs/G/runtime.object.o; 
	ldc -nodefaultlib -Imindrt/. -c invariant.d -ofdsss_objs/G/runtime.invariant.o; 
	ldc -nodefaultlib -Imindrt/. -c dstubs.d -ofdsss_objs/G/runtime.dstubs.o; 
	ldc -nodefaultlib -Imindrt/. -c util.d -ofdsss_objs/G/runtime.util.o; 
	ldc -nodefaultlib -Imindrt/. -c std/stdarg.d -ofdsss_objs/G/runtime.std.stdarg.o;
	ldc -nodefaultlib -Imindrt/. -c std/moduleinit.d -ofdsss_objs/G/runtime.std.moduleinit.o;
	ldc -nodefaultlib -Imindrt/. -c std/intrinsic.d -ofdsss_objs/G/runtime.std.intrinsic.o;
	ldc -nodefaultlib -Imindrt/. -c std/moduleinit.d -ofdsss_objs/G/runtime.std.moduleinit.o;
	ldc -nodefaultlib -Imindrt/. -c std/typeinfo/ti_AC.d -ofdsss_objs/G/runtime.std.typeinfo.ti_AC.o;
	ldc -nodefaultlib -Imindrt/. -c std/typeinfo/ti_Acdouble.d -ofdsss_objs/G/runtime.std.typeinfo.ti_Acdouble.o;
	ldc -nodefaultlib -Imindrt/. -c std/typeinfo/ti_Acfloat.d -ofdsss_objs/G/runtime.std.typeinfo.ti_Acfloat.o;
	ldc -nodefaultlib -Imindrt/. -c std/typeinfo/ti_Ag.d -ofdsss_objs/G/runtime.std.typeinfo.ti_Ag.o;
	ldc -nodefaultlib -Imindrt/. -c std/typeinfo/ti_Aint.d -ofdsss_objs/G/runtime.std.typeinfo.ti_Aint.o;
	ldc -nodefaultlib -Imindrt/. -c std/typeinfo/ti_Along.d -ofdsss_objs/G/runtime.std.typeinfo.ti_Along.o;
	ldc -nodefaultlib -Imindrt/. -c std/typeinfo/ti_Areal.d -ofdsss_objs/G/runtime.std.typeinfo.ti_Areal.o;
	ldc -nodefaultlib -Imindrt/. -c std/typeinfo/ti_Ashort.d -ofdsss_objs/G/runtime.std.typeinfo.ti_Ashort.o;
	ldc -nodefaultlib -Imindrt/. -c std/typeinfo/ti_C.d -ofdsss_objs/G/runtime.std.typeinfo.ti_C.o;
	ldc -nodefaultlib -Imindrt/. -c std/typeinfo/ti_byte.d -ofdsss_objs/G/runtime.std.typeinfo.ti_byte.o;
	ldc -nodefaultlib -Imindrt/. -c std/typeinfo/ti_cdouble.d -ofdsss_objs/G/runtime.std.typeinfo.ti_cdouble.o;
	ldc -nodefaultlib -Imindrt/. -c std/typeinfo/ti_cfloat.d -ofdsss_objs/G/runtime.std.typeinfo.ti_cfloat.o;
	ldc -nodefaultlib -Imindrt/. -c std/typeinfo/ti_char.d -ofdsss_objs/G/runtime.std.typeinfo.ti_char.o;
	ldc -nodefaultlib -Imindrt/. -c std/typeinfo/ti_creal.d -ofdsss_objs/G/runtime.std.typeinfo.ti_creal.o;
	ldc -nodefaultlib -Imindrt/. -c std/typeinfo/ti_dchar.d -ofdsss_objs/G/runtime.std.typeinfo.ti_dchar.o;
	ldc -nodefaultlib -Imindrt/. -c std/typeinfo/ti_delegate.d -ofdsss_objs/G/runtime.std.typeinfo.ti_delegate.o;
	ldc -nodefaultlib -Imindrt/. -c std/typeinfo/ti_double.d -ofdsss_objs/G/runtime.std.typeinfo.ti_double.o;
	ldc -nodefaultlib -Imindrt/. -c std/typeinfo/ti_float.d -ofdsss_objs/G/runtime.std.typeinfo.ti_float.o;
	ldc -nodefaultlib -Imindrt/. -c std/typeinfo/ti_idouble.d -ofdsss_objs/G/runtime.std.typeinfo.ti_idouble.o;
	ldc -nodefaultlib -Imindrt/. -c std/typeinfo/ti_ifloat.d -ofdsss_objs/G/runtime.std.typeinfo.ti_ifloat.o;
	ldc -nodefaultlib -Imindrt/. -c std/typeinfo/ti_int.d -ofdsss_objs/G/runtime.std.typeinfo.ti_int.o;
	ldc -nodefaultlib -Imindrt/. -c std/typeinfo/ti_ireal.d -ofdsss_objs/G/runtime.std.typeinfo.ti_ireal.o;
	ldc -nodefaultlib -Imindrt/. -c std/typeinfo/ti_long.d -ofdsss_objs/G/runtime.std.typeinfo.ti_long.o;
	ldc -nodefaultlib -Imindrt/. -c std/typeinfo/ti_ptr.d -ofdsss_objs/G/runtime.std.typeinfo.ti_ptr.o;
	ldc -nodefaultlib -Imindrt/. -c std/typeinfo/ti_real.d -ofdsss_objs/G/runtime.std.typeinfo.ti_real.o;
	ldc -nodefaultlib -Imindrt/. -c std/typeinfo/ti_short.d -ofdsss_objs/G/runtime.std.typeinfo.ti_short.o;
	ldc -nodefaultlib -Imindrt/. -c std/typeinfo/ti_ubyte.d -ofdsss_objs/G/runtime.std.typeinfo.ti_ubyte.o;
	ldc -nodefaultlib -Imindrt/. -c std/typeinfo/ti_uint.d -ofdsss_objs/G/runtime.std.typeinfo.ti_uint.o;
	ldc -nodefaultlib -Imindrt/. -c std/typeinfo/ti_ulong.d -ofdsss_objs/G/runtime.std.typeinfo.ti_ulong.o;
	ldc -nodefaultlib -Imindrt/. -c std/typeinfo/ti_ushort.d -ofdsss_objs/G/runtime.std.typeinfo.ti_ushort.o;
	ldc -nodefaultlib -Imindrt/. -c std/typeinfo/ti_void.d -ofdsss_objs/G/runtime.std.typeinfo.ti_void.o;
	ldc -nodefaultlib -Imindrt/. -c std/typeinfo/ti_wchar.d -ofdsss_objs/G/runtime.std.typeinfo.ti_wchar.o;
	ar rcs mindrt.a dsss_objs/G/*.o

