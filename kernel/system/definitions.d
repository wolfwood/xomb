/*
 * The structures that define specific pieces of information the kernel collects
 */

module kernel.system.definitions;

// This structure keeps track of information pertaining to onboard memory.
struct Memory {
	// The size of the RAM.
	ulong length;

	// The Virtual location of RAM
	void* virtualStart;
}

// This structure keeps track of modules loaded alongside the kernel.
struct Module {
	// The location and length of the module.
	ubyte* start;
	ulong length;

	ubyte* virtualStart;

	// The name of the module, if given.
	uint nameLength;
	char[64] name;
}

// This enum is for the Region structure
// It contains human-read information about the type of region.
enum RegionType: ubyte {
	// The region is special reserved data from the BIOS
	Reserved,

	// This signifies that this region is the kernel
	Kernel,
}

// This structure keeps track of special memory regions.
struct Region {
	// The location and length of the region
	ubyte* start;
	ulong length;

	// The virtual location of the region
	ubyte* virtualStart;

	// The type of region. See above for a list of values.
	RegionType type;
}

// This structure keeps information about the disks found in the system.
struct Disk {
	// Some identifing number for the drive, as reported by the system.
	ulong number;

	// Typical information about a mechanical hard disk.
	ulong cylinders;
	ulong heads;
	ulong sectors;

	// The ports used to communicate with the disk, if any.
	uint numPorts;
	ushort[32] ports;
}

// This structure stores information about the processors available
// in the system.
struct Processor {
}



