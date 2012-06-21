module user.syscall;

import user.nativecall;
import user.util;
import user.types;

// Errors
enum SyscallError : ulong {
	OK = 0,
	Failcopter
}

// IDs of the system calls
enum SyscallID : ulong {
	PerfPoll,
	Create,
	Map,
	//Close,
	CreateAddressSpace,
	Yield,
  MakeDeviceGib,
}

// Names of system calls
alias Tuple! (
	"perfPoll",			// perfPoll()
	"create",			// create()
	"map",				// map()
	//"close",      // close()
	"createAddressSpace", // createAddressSpace()
	"yield",			// yield()
	"makeDeviceGib"
) SyscallNames;


// Return types for each system call
alias Tuple! (
	void,			// perfPoll
	ubyte[],		// create
	void,			// map
	AddressSpace,	// createAddressSpace
	void,			// yield
	bool      // mkdevgib
) SyscallRetTypes;

struct CreateArgs {
	ubyte[] location;
	AccessMode mode;
}

struct MapArgs {
	AddressSpace dest;
	ubyte[] location;
	ubyte* destination;
	AccessMode mode;
}

struct CreateAddressSpaceArgs {
}

struct YieldArgs {
	AddressSpace dest;
	ulong idx;
}

struct PerfPollArgs {
	uint event;
}

struct MakeDeviceGibArgs{
	ubyte* gib;
	PhysicalAddress physAddr;
	ulong regionLength;
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
