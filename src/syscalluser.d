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

struct AddArgs
{
	long a, b;
}

struct AllocPageArgs
{
	long num;
}

struct ExitArgs
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
	//   so these should be in stack already!

	// I assume such in the syscall handler
	// so allow a non-naked function here

	asm
	{
		"syscall";
	}

	return 0;
}

template MakeSyscall(SyscallID ID, char[] name, RetType, ParamStruct)
{
	const char[] MakeSyscall =
RetType.stringof ~ ` ` ~ name ~ `(Tuple!` ~ typeof(ParamStruct.tupleof).stringof ~ ` args)
{
	` ~ RetType.stringof ~ ` ret;
	` ~ ParamStruct.stringof ~ ` argStruct;

	foreach(i, arg; args) {
		argStruct.tupleof[i] = arg;
		kprintfln("arg %d = %d", i, argStruct.tupleof[i]);
	}
									
	kprintfln("ARGSTRUCT: 0x%x", &argStruct);

	auto err = nativeSyscall(` ~ Itoa!(cast(ulong)ID) ~ `, &ret, &argStruct);

	// check err!

	return ret;
}`;
}

mixin(MakeSyscall!(SyscallID.Add, "add", ulong, AddArgs));
