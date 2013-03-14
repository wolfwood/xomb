module user.types;

// --- Constants ---
const ulong oneGB = 1024*1024*1024UL;
const ulong fourKB = 4096UL;
const ulong twoMB = fourKB*512;

// --- Special Types, casting to one of these means you are doing it wrong :) ---
typedef ubyte* AddressSpace;
typedef ubyte* PhysicalAddress;

// no longer a ubyte* as it is digested by a page walk or traversal
alias ulong AddressFragment;


// XXX: make this a ulong aligned with PTE bits?
enum AccessMode : uint {
	Read = 0,

	// bits that get encoded in the available bits
	Global = 1,
	AllocOnAccess = 2,

	MapOnce = 4,
	CopyOnWrite = 8,

	PrivilegedGlobal = 16,
	PrivilegedExecutable = 32,

	// use Indicators
	Segment = 64,
	RootPageTable = 128,
	Device = 256, // good enough for isTTY?

	// Permissions
	Delete = 512,
	// bits that are encoded in hardware defined PTE bits
	Writable = 1 <<  14,
	User = 1 << 15,
	Executable = 1 << 16,

	// Size?

	// Default policies
	DefaultUser = Writable | AllocOnAccess | User,
	DefaultKernel = Writable | AllocOnAccess,
	Tombstone = User, // access will fault and be directed to userspace

	// flags that are always permitted in syscalls
	SyscallStrictMask = Global | AllocOnAccess | MapOnce | CopyOnWrite | Writable
	  | User | Executable,

	// Flags that go in the available bits
	AvailableMask = Global | AllocOnAccess | MapOnce | CopyOnWrite |
	  PrivilegedGlobal | PrivilegedExecutable | Segment | RootPageTable |
	  Device | Delete
}
