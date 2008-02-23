module syscalluser;

import util;

enum SyscallID : ulong
{
	Add = 0,
	AllocPage,
	Exit
}

char[][] SyscallNames =
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

extern(C) long nativeSyscall(ulong ID, void* ret, void* params)
{
	// ...
	return 0;
}

template MakeSyscall(SyscallID ID, char[] name, RetType, ParamStruct)
{
	const char[] MakeSyscall =
RetType.stringof ~ ` ` ~ name ~ `(Tuple!` ~ typeof(ParamStruct.tupleof).stringof ~ ` args)
{
	` ~ RetType.stringof ~ ` ret;
	` ~ ParamStruct.stringof ~ ` argStruct;
	foreach(i, arg; args)
		argStruct.tupleof[i] = arg;

	auto err = nativeSyscall(` ~ Itoa!(cast(ulong)ID) ~ `, &ret, &argStruct);

	// check err!

	return ret;
}`;
}

mixin(MakeSyscall!(SyscallID.Add, "add", ulong, AddArgs));