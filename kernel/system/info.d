/*
 *  This module contains the System namespace, which gives access to all
 *    information the kernel has collected.
 */

module kernel.system.info;

// import the specific types of information
public import kernel.system.definitions;

struct System
{
static:
public:

	// The information about RAM
	Memory memoryInfo;

	// This region is specifically the kernel
	Region kernel = { type: RegionType.Kernel };

	// Information about specific memory regions
	uint numRegions;
	Region[10] regionInfo;

	// Information about modules that have been loaded
	// during the boot process.
	uint numModules;
	Module[10] moduleInfo;

	// Information about disks available to the system
	uint numDisks;
	Disk[10] diskInfo;

	// Information about each processor available.
	uint numProcessors;
	Processor[256] processorInfo;
}
