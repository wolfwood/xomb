module syscalluser;

import util;

enum SyscallID : ulong
{
	Add = 0,
	AllocPage,
	Exit
}

static const char[][] SyscallNames =
[
	SyscallID.Add: "add",
	SyscallID.AllocPage: "allocPage",
	SyscallID.Exit: "exit"
];

struct addArgs
{
	long a, b;
}

struct allocPageArgs
{
	long num;
}

struct exitArgs
{
	long retVal;
}

import vga;

extern(C) long nativeSyscall(ulong ID, void* ret, void* params)
{
	// arguments for x86-64:
	// %rdi, %rsi, %rdx, %rcx, %r8, %r9
	// %rcx is also used for the return address for the syscall
	//   but we only need three arguments
	//   so these should be there!

	// I assume such in the syscall handler

	asm
	{	
		naked;
		"syscall";
		"xorq %%rax, %%rax";
		"retq";
	}
}

template MakeSyscall(SyscallID ID, char[] name, RetType, ParamStruct)
{
	const char[] MakeSyscall =
RetType.stringof ~ ` ` ~ name ~ `(Tuple!` ~ typeof(ParamStruct.tupleof).stringof ~ ` args)
{
	` ~ (is(RetType == void) ? "ulong ret;" : RetType.stringof ~ ` ret;  `)
	 ~ ParamStruct.stringof ~ ` argStruct;

	foreach(i, arg; args)
		argStruct.tupleof[i] = arg;

	auto err = nativeSyscall(` ~ Itoa!(cast(ulong)ID) ~ `, &ret, &argStruct);

	// check err!

	return ret;
}`;
}

mixin(MakeSyscall!(SyscallID.Add, "add", ulong, addArgs));
mixin(MakeSyscall!(SyscallID.AllocPage, "allocPage", void*, allocPageArgs));
mixin(MakeSyscall!(SyscallID.Exit, "exit", void, exitArgs));
