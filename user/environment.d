module user.environment;

typedef ubyte* AddressSpace;

const ulong oneGB = 1024*1024*1024UL;

// XXX make this a ulong alligned with PTE bits?
enum AccessMode : uint {

	// bits that get encoded in the available bits
	Global = 1,
		AllocOnAccess = 2,
	 
		MapOnce = 4,
		CopyOnWrite = 8,
		
		PrivilgedGlobal = 16.
		PrivilegedExecutable = 32,

		// use Indicators
		Segment = 64,
		RootPageTable = 128,
		Device = 256, // good enough for isTTY?

		// bits that are encoded in hardware defined PTE bits
		Writable = 1<<  14,
		Kernel = 1 << 15,
		Executable = 1<< 16.
		
		// Size? - could be encoded w/ paging trick on address

		// Default policies
		DefaultUser = Writable,
		DefaultKernel = Writable | AllocOnAccess | Kernel
}
