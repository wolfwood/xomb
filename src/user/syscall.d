module user.syscall;

import kernel.core.util;
import kernel.arch.usersyscall;

enum SyscallID : ulong
{
	Add = 0,
	AllocPage,
	Exit,
	FreePage
}

enum SyscallError : ulong
{
	OK = 0,
	Failcopter
}

alias Tuple!
(
	"add", // Add
	"allocPage", // AllocPage
	"exit", // Exit
	"freePage" // FreePage
) SyscallNames;

alias Tuple!
(
	long, // Add
	ulong, // AllocPage
	void, // Exit
	void // FreePage
) SyscallRetTypes;

struct AddArgs
{
	long a, b;
}

struct AllocPageArgs
{
	void* va;
}

struct ExitArgs
{
	long retVal;
}

struct FreePageArgs
{
	void* ptr;
}

// This template exists because of a bug in the DMDFE; something like Templ!(tuple[idx]) fails for some reason
template SyscallName(uint ID)
{
	const char[] SyscallName = SyscallNames[ID];
}

template ArgsStruct(uint ID)
{
	const char[] ArgsStruct = Capitalize!(SyscallName!(ID)) ~ "Args";
}

template MakeSyscall(uint ID)
{
	const char[] MakeSyscall =
SyscallRetTypes[ID].stringof ~ ` ` ~ SyscallNames[ID] ~ `(Tuple!` ~ typeof(mixin(ArgsStruct!(ID)).tupleof).stringof ~ ` args)
{
	` ~ (is(SyscallRetTypes[ID] == void) ? "ulong ret;" : SyscallRetTypes[ID].stringof ~ ` ret;  `)
	~ ArgsStruct!(ID) ~ ` argStruct;

	foreach(i, arg; args)
		argStruct.tupleof[i] = arg;

	auto err = nativeSyscall(` ~ ID.stringof ~ `, &ret, &argStruct);

	// check err!

	return ret;
}`;
}

mixin(Reduce!(Cat, Map!(MakeSyscall, Range!(SyscallID.max + 1))));
