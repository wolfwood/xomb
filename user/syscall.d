module user.syscall;

import user.nativecall;
import user.util;

import user.console;
import user.keyboard;

import user.ramfs;

extern(C):

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
	RequestConsole,
	AllocPage,
	Exit,
	Fork,
		Open,
		CanHasHwThread,
		YieldHwThread,
		ReturnHwThread
}

// Names of system calls
alias Tuple!
(
	"add",				// add()
	"requestConsole",	// requestConsole()
	"allocPage",		// allocPage()
	"exit",				// exit()
	"fork",				// fork()
	"open",        // open()
	"canHasHwThread",   // canHasCpu(numcpus, void &function(void))
	"yieldHwThread",    // YieldHwThread
	"returnHwThread"
) SyscallNames;


// Return types for each system call
alias Tuple!
(
	int,			// add
	void,			// requestConsole
	int,			// allocPage
	void,			// exit
	int,				// fork
	int,     // open
	int,     // vfork()
	void,    // YieldHwThread
	void    // returnHwThread
) SyscallRetTypes;

// Parameters to system call
struct AddArgs {
	int a, b;
}

struct RequestConsoleArgs {
	ConsoleInfo* cinfo;
}

struct AllocPageArgs {
	void* virtualAddress;
}

struct ExitArgs {
	long retVal;
}

struct ForkArgs {
}

struct OpenArgs {
	char[] path;
	Inode** node;
}

struct CanHasHwThreadArgs {
	int numcpus;
	void* entry;
}

struct YieldHwThreadArgs{
}

struct ReturnHwThreadArgs{
}

// XXX: This template exists because of a bug in the DMDFE; something like Templ!(tuple[idx]) fails for some reason
template SyscallName(uint ID) {
	const char[] SyscallName = SyscallNames[ID];
}

template ArgsStruct(uint ID) {
	const char[] ArgsStruct = Capitalize!(SyscallName!(ID)) ~ "Args";
}

template MakeSyscall(uint ID) {
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

