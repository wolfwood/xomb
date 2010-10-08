module user.environment;

typedef ubyte* AddressSpace;

enum AccessMode : uint {
	Writable = 1,
	Global = 2,
	Kernel = 4,
	Arrowed = 8,
}
