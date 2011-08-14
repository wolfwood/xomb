/*
 * The structures that define specific pieces of information the kernel collects
 */

module kernel.system.definitions;

import kernel.dev.pci;

import user.types;

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
	PhysicalAddress start;
	ulong length;

	// The name of the module, if given.
	char[] name;
	char[128] nameSpace;

	// The path to this module on the file system
	char[] path;
	char[128] pathSpace;
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
	PhysicalAddress start;
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
	Cache L1ICache;
	Cache L1DCache;
	Cache L2Cache;
	Cache L3Cache;
}

// This structure stores information about processor caches available
struct Cache {
	uint associativity;
	uint length;
	uint blockSize;
	uint linesPerSector;
}

struct Device {
	enum BusType {
		PCI,
	}

	BusType type;

	union Bus {
		PCIDevice pci;
	}

	Bus bus;
}
