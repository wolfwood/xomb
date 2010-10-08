module user.syscall;

import user.nativecall;
import user.util;
import user.environment;

// Errors
enum SyscallError : ulong {
	OK = 0,
	Failcopter
}

// IDs of the system calls
enum SyscallID : ulong {
	AllocPage,
	Exit,
	PerfPoll,
	Open,
	Create,
	CreateAddressSpace,
	Map,
	Schedule,
	Yield,
	CreateEnv,
}

// Names of system calls
alias Tuple! (
	"allocPage",		// allocPage()
	"exit",				// exit()
	"perfPoll",			// perfPoll()
	"open",				// open()
	"create",			// create()
	"createAddressSpace", // createAddressSpace()
	"map",				// map()
	"schedule",			// schedule()
	"yield",			// yield()
	"createEnv"			// createEnv()
) SyscallNames;


// Return types for each system call
alias Tuple! (
	int,			// allocPage
	void,			// exit
	void,			// perfPoll
	bool,			// open
	ubyte[],		// create
	AddressSpace,	// createAddressSpace
	void,			// map
	void,			// schedule
	void,			// yield
	uint			// createEnv
) SyscallRetTypes;

// Parameters to system call

struct AllocPageArgs {
	void* virtualAddress;
}

struct ExitArgs {
	long retVal;
}

struct ForkArgs {
}

struct OpenArgs {
	ubyte* address;
	int mode;
}

struct CreateArgs {
	ubyte* location;
	ulong size;
	int mode;
}

struct MapArgs {
	AddressSpace dest;
	ubyte* location;
	ubyte* destination;
	int mode;
}

struct CloseArgs {
	ubyte* location;
}

struct PerfPollArgs {
	uint event;
}

struct CreateAddressSpaceArgs {
}

struct ScheduleArgs {
	AddressSpace dest;
}

struct YieldArgs {
	int eid;
}

struct CreateEnvArgs {
	char[] name;
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

	` ~ (is(SyscallRetTypes[ID] == void) ? "" : "return ret;") ~ `
}`;
}

mixin(Reduce!(Cat, Map!(MakeSyscall, Range!(SyscallID.max + 1))));
