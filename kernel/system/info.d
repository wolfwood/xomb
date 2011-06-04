/*
 *  This module contains the System namespace, which gives access to all
 *    information the kernel has collected.
 */

module kernel.system.info;

// import the specific types of information
public import kernel.system.definitions;

struct System {
static:
public:

	// The information about RAM
	Memory memory;

	// This region is specifically the kernel
	Region kernel = { type: RegionType.Kernel };

	// Information about specific memory regions
	uint numRegions;
	const uint MAX_REGIONS = 16;
	Region[MAX_REGIONS] regionInfo;

	// Information about modules that have been loaded
	// during the boot process.
	uint numModules;
	const uint MAX_MODULES = 16;
	Module[MAX_MODULES] moduleInfo;

	// Information about disks available to the system
	uint numDisks;
	const uint MAX_DISKS = 16;
	Disk[MAX_DISKS] diskInfo;

	// Information about each processor available.
	uint numProcessors = 1; // Assume at least one.
	const uint MAX_PROCESSORS = 256;
	Processor[MAX_PROCESSORS] processorInfo;

	uint numDevices;
	const uint MAX_DEVICES = 256;
	Device[MAX_DEVICES] deviceInfo;

	char[128] cmdlineStorage;
	char[] cmdline;
}
