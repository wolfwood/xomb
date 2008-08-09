module user.syscall;

import kernel.core.util;
import kernel.arch.select;

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
		//"xorq %%rax, %%rax";
		"retq";
	}
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
