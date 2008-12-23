module user.syscall;

import kernel.core.util;
import kernel.arch.usersyscall;

// Errors
enum SyscallError : ulong
{
	OK = 0,
	Failcopter
}

// IDs of the system calls
enum SyscallID : ulong
{
	Add = 0,
	AllocPage,
	Exit,
	FreePage,
	Yield,
	Echo,
	Grabch,
	Depositch
}

// Names of system calls
alias Tuple!
(
	"add",			// add()
	"allocPage",	// allocPage()
	"exit",			// exit()
	"freePage",		// freePage()
	"yield",		// yield()
	"echo",			// echo()
	"grabch",		// grabch()
	"depositch"		// depositch()
) SyscallNames;


// Return types for each system call
alias Tuple!
(
	long,		// add
	void*,		// allocPage
	void,		// exit
	void,		// freePage
	void,		// yield
	void,		// echo
	char,		// grabch
	void		// depositch
) SyscallRetTypes;

// Parameters to system call
struct AddArgs
{
	long a, b;
}

struct AllocPageArgs
{
}

struct ExitArgs
{
	long retVal;
}

struct FreePageArgs
{
}

struct YieldArgs
{
}

struct EchoArgs
{
	char [] str;
}

struct GrabchArgs
{
}

struct DepositchArgs
{
	char ch;
}








// XXX: This template exists because of a bug in the DMDFE; something like Templ!(tuple[idx]) fails for some reason
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
