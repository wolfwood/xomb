// D import file generated from 'mindrt/object.d'
module object;

import user.architecture.mutex;

extern (C) Object _d_allocclass(ClassInfo ci);

static if((ubyte*).sizeof == 8)
{
    version = Arch64;
}
else
{
    static if((ubyte*).sizeof == 4)
{
    version = Arch32;
}
}
version (Arch32)
{
    alias uint size_t;
    alias int ptrdiff_t;
    alias uint hash_t;
}
else
{
    alias ulong size_t;
    alias long ptrdiff_t;
    alias ulong hash_t;
}
struct PointerMap
{
    size_t[] bits = [1,1,0];
    size_t size();
}
struct Monitor
{
    void* impl;
    size_t devt_len;
    void* devt;
    Mutex mutex;
}
class Object
{
    void dispose()
{
}
    char[] toString()
{
return this.classinfo.name;
}
    hash_t toHash()
{
return cast(uint)cast(void*)this;
}
    int opCmp(Object o);
    int opEquals(Object o)
{
return cast(int)(this is o);
}
}
struct Interface
{
    ClassInfo classinfo;
    void*[] vtbl;
    int offset;
}
class ClassInfo : Object
{
    byte[] init;
    char[] name;
    void*[] vtbl;
    Interface[] interfaces;
    ClassInfo base;
    void* destructor;
    void function(Object) classInvariant;
    uint flags;
    void* deallocator;
    OffsetTypeInfo[] offTi;
    void* defaultConstructor;
    TypeInfo typeinfo;
    static ClassInfo find(char[] classname)
{
return null;
}

    Object create()
{
if (flags & 8 && !defaultConstructor)
return null;
Object o = _d_allocclass(this);
(cast(byte*)o)[0..init.length] = init[];
if (flags & 8 && defaultConstructor)
{
auto ctor = cast(Object function(Object))defaultConstructor;
return ctor(o);
}
return o;
}
}
class ModuleInfo
{
    char[] name;
    ModuleInfo[] importedModules;
    ClassInfo[] localClasses;
    uint flags;
    void function() ctor;
    void function() dtor;
    void function() unitTest;
    void* xgetMembers;
    void function() ictor;
    static int opApply(int delegate(ref ModuleInfo) dg);

}
extern (C) ModuleInfo[] _moduleinfo_array;

struct ModuleReference
{
    ModuleReference* next;
    ModuleInfo mod;
}
ModuleInfo[] _moduleinfo_dtors;
uint _moduleinfo_dtors_i;
struct OffsetTypeInfo
{
    size_t offset;
    TypeInfo ti;
}
class TypeInfo
{
    hash_t getHash(void* p)
{
return cast(uint)p;
}
    int equals(void* p1, void* p2)
{
return cast(int)(p1 == p2);
}
    int compare(void* p1, void* p2)
{
return 0;
}
    size_t tsize()
{
return 0;
}
    void swap(void* p1, void* p2)
{
size_t n = tsize();
{
for (size_t i = 0;
 i < n; i++)
{
{
byte t;
t = (cast(byte*)p1)[i];
(cast(byte*)p1)[i] = (cast(byte*)p2)[i];
(cast(byte*)p2)[i] = t;
}
}
}
}
    void[] init()
{
return null;
}
    TypeInfo next()
{
return null;
}
    uint flags()
{
return 0;
}
    void pointermap()
{
}
    OffsetTypeInfo[] offTi()
{
return null;
}
    hash_t toHash();
    int opCmp(Object o)
{
if (this is o)
return 0;
TypeInfo ti = cast(TypeInfo)o;
if (ti is null)
return 1;
char[] t = this.toString();
char[] other = this.toString();
typeid(typeof(this.toString())).compare(&t,&other);
}
    int opEquals(Object o)
{
if (this is o)
return 1;
TypeInfo ti = cast(TypeInfo)o;
return cast(int)(ti && this.toString() == ti.toString());
}
}
class TypeInfo_Typedef : TypeInfo
{
    char[] toString()
{
return name;
}
    int opEquals(Object o)
{
TypeInfo_Typedef c;
return cast(int)(this is o || (c = cast(TypeInfo_Typedef)o) !is null && this.name == c.name && this.base == c.base);
}
    hash_t getHash(void* p)
{
return base.getHash(p);
}
    int equals(void* p1, void* p2)
{
return base.equals(p1,p2);
}
    int compare(void* p1, void* p2)
{
return base.compare(p1,p2);
}
    size_t tsize()
{
return base.tsize();
}
    void swap(void* p1, void* p2)
{
return base.swap(p1,p2);
}
    TypeInfo next()
{
return base.next();
}
    uint flags()
{
return base.flags();
}
    void[] init()
{
return m_init.length ? m_init : base.init();
}
    TypeInfo base;
    char[] name;
    void[] m_init;
}
class TypeInfo_Enum : TypeInfo_Typedef
{
}
class TypeInfo_Pointer : TypeInfo
{
    char[] toString()
{
return m_next.toString() ~ "*";
}
    int opEquals(Object o)
{
TypeInfo_Pointer c;
return this is o || (c = cast(TypeInfo_Pointer)o) !is null && this.m_next == c.m_next;
}
    hash_t getHash(void* p)
{
return cast(uint)*cast(void**)p;
}
    int equals(void* p1, void* p2)
{
return cast(int)(*cast(void**)p1 == *cast(void**)p2);
}
    int compare(void* p1, void* p2)
{
if (*cast(void**)p1 < *cast(void**)p2)
return -1;
else
if (*cast(void**)p1 > *cast(void**)p2)
return 1;
else
return 0;
}
    size_t tsize()
{
return (void*).sizeof;
}
    void swap(void* p1, void* p2)
{
void* tmp;
tmp = *cast(void**)p1;
*cast(void**)p1 = *cast(void**)p2;
*cast(void**)p2 = tmp;
}
    TypeInfo next()
{
return m_next;
}
    uint flags()
{
return 1;
}
    TypeInfo m_next;
}
class TypeInfo_Array : TypeInfo
{
    char[] toString()
{
return value.toString() ~ "[]";
}
    int opEquals(Object o)
{
TypeInfo_Array c;
return cast(int)(this is o || (c = cast(TypeInfo_Array)o) !is null && this.value == c.value);
}
    hash_t getHash(void* p)
{
size_t sz = value.tsize();
hash_t hash = 0;
void[] a = *cast(void[]*)p;
{
for (size_t i = 0;
 i < a.length; i++)
{
hash += value.getHash(a.ptr + i * sz);
}
}
return hash;
}
    int equals(void* p1, void* p2)
{
void[] a1 = *cast(void[]*)p1;
void[] a2 = *cast(void[]*)p2;
if (a1.length != a2.length)
return 0;
size_t sz = value.tsize();
{
for (size_t i = 0;
 i < a1.length; i++)
{
{
if (!value.equals(a1.ptr + i * sz,a2.ptr + i * sz))
return 0;
}
}
}
return 1;
}
    int compare(void* p1, void* p2)
{
void[] a1 = *cast(void[]*)p1;
void[] a2 = *cast(void[]*)p2;
size_t sz = value.tsize();
size_t len = a1.length;
if (a2.length < len)
len = a2.length;
{
for (size_t u = 0;
 u < len; u++)
{
{
int result = value.compare(a1.ptr + u * sz,a2.ptr + u * sz);
if (result)
return result;
}
}
}
return cast(int)a1.length - cast(int)a2.length;
}
    size_t tsize()
{
return (void[]).sizeof;
}
    void swap(void* p1, void* p2)
{
void[] tmp;
tmp = *cast(void[]*)p1;
*cast(void[]*)p1 = *cast(void[]*)p2;
*cast(void[]*)p2 = tmp;
}
    TypeInfo value;
    TypeInfo next()
{
return value;
}
    uint flags()
{
return 1;
}
    void pointermap()
{
}
}
class TypeInfo_StaticArray : TypeInfo
{
    char[] toString()
{
char[20] buf;
return value.toString() ~ "[" ~ itoa(buf,'d',len) ~ "]";
}
    int opEquals(Object o)
{
TypeInfo_StaticArray c;
return cast(int)(this is o || (c = cast(TypeInfo_StaticArray)o) !is null && this.len == c.len && this.value == c.value);
}
    hash_t getHash(void* p)
{
size_t sz = value.tsize();
hash_t hash = 0;
{
for (size_t i = 0;
 i < len; i++)
{
hash += value.getHash(p + i * sz);
}
}
return hash;
}
    int equals(void* p1, void* p2)
{
size_t sz = value.tsize();
{
for (size_t u = 0;
 u < len; u++)
{
{
if (!value.equals(p1 + u * sz,p2 + u * sz))
return 0;
}
}
}
return 1;
}
    int compare(void* p1, void* p2)
{
size_t sz = value.tsize();
{
for (size_t u = 0;
 u < len; u++)
{
{
int result = value.compare(p1 + u * sz,p2 + u * sz);
if (result)
return result;
}
}
}
return 0;
}
    size_t tsize()
{
return len * value.tsize();
}
    void swap(void* p1, void* p2)
{
void* tmp;
size_t sz = value.tsize();
ubyte[16] buffer;
void* pbuffer;
if (sz < buffer.sizeof)
tmp = buffer.ptr;
else
tmp = (pbuffer = (new void[](sz)).ptr);
{
for (size_t u = 0;
 u < len; u += sz)
{
{
size_t o = u * sz;
tmp[0..sz] = (p1 + o)[0..sz];
(p1 + o)[0..sz] = (p2 + o)[0..sz];
(p2 + o)[0..sz] = tmp[0..sz];
}
}
}
if (pbuffer)
delete pbuffer;
}
    void[] init()
{
return value.init();
}
    TypeInfo next()
{
return value;
}
    uint flags()
{
return value.flags();
}
    TypeInfo value;
    size_t len;
}
class TypeInfo_AssociativeArray : TypeInfo
{
    char[] toString()
{
return value.toString() ~ "[" ~ key.toString() ~ "]";
}
    int opEquals(Object o)
{
TypeInfo_AssociativeArray c;
return this is o || (c = cast(TypeInfo_AssociativeArray)o) !is null && this.key == c.key && this.value == c.value;
}
    size_t tsize()
{
return (char[int]).sizeof;
}
    TypeInfo next()
{
return value;
}
    uint flags()
{
return 1;
}
    TypeInfo value;
    TypeInfo key;
}
class TypeInfo_Function : TypeInfo
{
    char[] toString()
{
return next.toString() ~ "()";
}
    int opEquals(Object o)
{
TypeInfo_Function c;
return this is o || (c = cast(TypeInfo_Function)o) !is null && this.next == c.next;
}
    size_t tsize()
{
return 0;
}
    TypeInfo next;
}
class TypeInfo_Delegate : TypeInfo
{
    char[] toString()
{
return next.toString() ~ " delegate()";
}
    int opEquals(Object o)
{
TypeInfo_Delegate c;
return this is o || (c = cast(TypeInfo_Delegate)o) !is null && this.next == c.next;
}
    size_t tsize()
{
alias int delegate() dg;
return dg.sizeof;
}
    uint flags()
{
return 1;
}
    TypeInfo next;
}
class TypeInfo_Class : TypeInfo
{
    char[] toString()
{
return info.name;
}
    int opEquals(Object o)
{
TypeInfo_Class c;
return this is o || (c = cast(TypeInfo_Class)o) !is null && this.info.name == c.classinfo.name;
}
    hash_t getHash(void* p)
{
Object o = *cast(Object*)p;
assert(o);
return o.toHash();
}
    int equals(void* p1, void* p2)
{
Object o1 = *cast(Object*)p1;
Object o2 = *cast(Object*)p2;
return o1 is o2 || o1 && o1.opEquals(o2);
}
    int compare(void* p1, void* p2)
{
Object o1 = *cast(Object*)p1;
Object o2 = *cast(Object*)p2;
int c = 0;
if (o1 !is o2)
{
if (o1)
{
if (!o2)
c = 1;
else
c = o1.opCmp(o2);
}
else
c = -1;
}
return c;
}
    size_t tsize()
{
return Object.sizeof;
}
    uint flags()
{
return 1;
}
    OffsetTypeInfo[] offTi()
{
return info.flags & 4 ? info.offTi : null;
}
    ClassInfo info;
}
class TypeInfo_Interface : TypeInfo
{
    char[] toString()
{
return info.name;
}
    int opEquals(Object o)
{
TypeInfo_Interface c;
return this is o || (c = cast(TypeInfo_Interface)o) !is null && this.info.name == c.classinfo.name;
}
    hash_t getHash(void* p)
{
Interface* pi = **cast(Interface***)*cast(void**)p;
Object o = cast(Object)(*cast(void**)p - pi.offset);
assert(o);
return o.toHash();
}
    int equals(void* p1, void* p2)
{
Interface* pi = **cast(Interface***)*cast(void**)p1;
Object o1 = cast(Object)(*cast(void**)p1 - pi.offset);
pi = **cast(Interface***)*cast(void**)p2;
Object o2 = cast(Object)(*cast(void**)p2 - pi.offset);
return o1 == o2 || o1 && o1.opCmp(o2) == 0;
}
    int compare(void* p1, void* p2)
{
Interface* pi = **cast(Interface***)*cast(void**)p1;
Object o1 = cast(Object)(*cast(void**)p1 - pi.offset);
pi = **cast(Interface***)*cast(void**)p2;
Object o2 = cast(Object)(*cast(void**)p2 - pi.offset);
int c = 0;
if (o1 != o2)
{
if (o1)
{
if (!o2)
c = 1;
else
c = o1.opCmp(o2);
}
else
c = -1;
}
return c;
}
    size_t tsize()
{
return Object.sizeof;
}
    uint flags()
{
return 1;
}
    ClassInfo info;
}
class TypeInfo_Struct : TypeInfo
{
    char[] toString()
{
return name;
}
    int opEquals(Object o)
{
TypeInfo_Struct s;
return this is o || (s = cast(TypeInfo_Struct)o) !is null && this.name == s.name && this.init.length == s.init.length;
}
    hash_t getHash(void* p)
{
hash_t h;
assert(p);
if (xtoHash)
{
h = (*xtoHash)(p);
}
else
{
{
for (size_t i = 0;
 i < init.length; i++)
{
{
h = h * 9 + *cast(ubyte*)p;
p++;
}
}
}
}
return h;
}
    int equals(void* p2, void* p1)
{
int c;
if (p1 == p2)
c = 1;
else
if (!p1 || !p2)
c = 0;
else
if (xopEquals)
c = (*xopEquals)(p1,p2);
else
c = memcmp(cast(ubyte*)p1,cast(ubyte*)p2,init.length) == 0;
return c;
}
    int compare(void* p2, void* p1)
{
int c = 0;
if (p1 != p2)
{
if (p1)
{
if (!p2)
c = 1;
else
if (xopCmp)
c = (*xopCmp)(p1,p2);
else
c = memcmp(cast(ubyte*)p1,cast(ubyte*)p2,init.length);
}
else
c = -1;
}
return c;
}
    size_t tsize()
{
return init.length;
}
    void[] init()
{
return m_init;
}
    uint flags()
{
return m_flags;
}
    char[] name;
    void[] m_init;
    hash_t function(void*) xtoHash;
    int function(void*, void*) xopEquals;
    int function(void*, void*) xopCmp;
    char[] function(void*) xtoString;
    uint m_flags;
}
class TypeInfo_Tuple : TypeInfo
{
    TypeInfo[] elements;
    char[] toString();
    int opEquals(Object o)
{
if (this is o)
return 1;
auto t = cast(TypeInfo_Tuple)o;
if (t && elements.length == t.elements.length)
{
{
for (size_t i = 0;
 i < elements.length; i++)
{
{
if (elements[i] != t.elements[i])
return 0;
}
}
}
return 1;
}
return 0;
}
    hash_t getHash(void* p)
{
assert(0);
}
    int equals(void* p1, void* p2)
{
assert(0);
}
    int compare(void* p1, void* p2)
{
assert(0);
}
    size_t tsize()
{
assert(0);
}
    void swap(void* p1, void* p2)
{
assert(0);
}
}
