module user.environment;

typedef ubyte* AddressSpace;

const ulong oneGB = 1024*1024*1024UL;

enum AccessMode : uint {

	// bits that get encoded in the available bits
	Global = 1,
		AllocOnAccess = 2,
	 
		// bits that are encoded in hardware defined PTE bits
		Writable = 4,
		Kernel = 8,

		// Default policies
		DefaultUser = Writable,
		DefaultKernel = Writable | AllocOnAccess | Kernel
}
