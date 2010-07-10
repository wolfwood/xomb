module user.syscall;

import user.nativecall;
import user.util;
public import user.environment;

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
	Close,

	CreateAddressSpace,
	Schedule,
	Yield,
}

// Names of system calls
alias Tuple! (
	"allocPage",		// allocPage()
	"exit",				// exit()

	"perfPoll",			// perfPoll()

	"open",				// open()
	"create",			// create()
	"close",			// close()

	"createAddressSpace", // createAddressSpace()
	"schedule",			// schedule()
	"yield"				// yield()
) SyscallNames;


// Return types for each system call
alias Tuple! (
	int,			// allocPage
	void,			// exit

	void,			// perfPoll

	ubyte*,			// open
	ubyte*,			// create
	void,			// close

	AddressSpace,	// createAddressSpace
	void,			// schedule
	void			// yield
) SyscallRetTypes;

// Parameters to system call
struct AddArgs {
	int a, b;
}

struct AllocPageArgs {
	void* virtualAddress;
}

struct ExitArgs {
	long retVal;
}

struct OpenArgs {
	AddressSpace dest;
	ubyte* address;
	int mode;
}

struct CreateArgs {
	int mode;
}

struct CloseArgs {
	AddressSpace dest;
	ubyte* location;
}

struct CreateAddressSpaceArgs {
}

struct ScheduleArgs {
	AddressSpace dest;
	ubyte* entry;
	ubyte* stack;
}

struct YieldArgs {
	AddressSpace dest;
}

struct PerfPollArgs {
	uint event;
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
