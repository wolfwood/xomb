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

	Memory memoryInfo;

	uint numRegions;
	Region[10] regionInfo;

	uint numModules;
	Module[10] moduleInfo;

	uint numDisks;
	Disk[10] diskInfo;

	uint numProcessors;
	Processor[256] processorInfo;
}
