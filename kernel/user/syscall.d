module user.syscall;

import kernel.core.util;
import kernel.arch.usersyscall;

// Errors
enum SyscallError : ulong
{
	OK = 0,
	Failcopter
}

// Return structures
struct KeyboardInfo
{
	short* buffer;
	uint bufferLength;

	int* writePointer;
	int* readPointer;
}

struct ConsoleInfo
{
	int xMax;
	int yMax;

	int xPos;
	int yPos;

	ubyte color;
	ubyte* buffer;
}

// IDs of the system calls
enum SyscallID : ulong
{
	Add = 0,
	AllocPage,
	Exit,
	FreePage,
	Yield,
	Error,
	DepositKey,
	InitKeyboard,
	InitConsole,
  MakeEnvironment,
  Fork,
  Exec
}

// Names of system calls
alias Tuple!
(
	"add",			// add()
	"allocPage",	// allocPage()
	"exit",			// exit()
	"freePage",		// freePage()
	"yield",		// yield()
	"error",		// error()
	"depositKey",	// depositKey()
	"initKeyboard",	// initKeyboard()
	"initConsole",	// initConsole()
  "makeEnvironment", //makeEnvironment()
  "fork", //fork()
  "exec" //exec()
) SyscallNames;


// Return types for each system call
alias Tuple!
(
	long,			// add
	void*,			// allocPage
	void,			// exit
	void,			// freePage
	void,			// yield
	void,			// error
	void,			// depositKey
	KeyboardInfo,	// initKeyboard
	ConsoleInfo,		// initConsole
  void, //makeEnvironment
  int, //fork
  int //exec
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

struct ErrorArgs
{
	char [] str;
}

struct DepositKeyArgs
{
	short ch;
}

struct InitKeyboardArgs
{
}


struct InitConsoleArgs
{
}

struct MakeEnvironmentArgs
{
  int id;
}

struct ForkArgs
{

}

struct ExecArgs
{

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
