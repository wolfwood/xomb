/*
 * mp.d
 *
 * This module implements the Multiprocessor Specification
 *
 */

module kernel.arch.x86_64.specs.mp;

// Log information and errors
import kernel.core.error;
import kernel.core.log;

// Printing
import kernel.core.kprintf;

// Bitfield!()
import kernel.core.util;

// The struct for MP specification
struct MP
{
static:
public:

	// This function will search for the MP tables.
	// It will return true when they have been found.
	bool hasTable()
	{
		return false;
	}

	ErrorVal readTable()
	{
		return ErrorVal.Success;
	}

private:


// -- Main Structure Definitions -- //


	// The main MP structure
	align(1) struct MPFloatingPointer {
		uint signature;
		uint mpConfigPointer;
		ubyte length;
		ubyte mpVersion;
		ubyte checksum;
		ubyte mpFeatures1;
		ubyte mpFeatures2;
		ubyte mpFeatures3;
		ubyte mpFeatures4;
		ubyte mpFeatures5;
	}

	// A supplementary configuration structure
	align(1) struct MPConfigurationTable {
		uint signature;
		ushort baseTableLength;
		ubyte revision;
		ubyte checksum;
		char[8] oemID;
		char[12] productID;
		uint oemTablePointer;
		ushort oemTableSize;
		ushort entryCount;
		uint addressOfLocalAPIC;
		ushort extendedTableLength;
		ubyte extendedTableChecksum;
		ubyte reserved;
	}


// -- Configuration Table Entries -- //


	// Defines the processors
	align(1) struct ProcessorEntry {
		ubyte entryType;	// 0
		ubyte localAPICID;
		ubyte localAPICVersion;
		ubyte cpuFlags;
		uint cpuSignature;
		uint cpuFeatureFlags;
		ulong reserved;

		mixin(Bitfield!(cpuFlags,
					"cpuEnabledBit", 1,
					"cpuBootstrapProcessorBit", 1,
					"reserved2", 6));
	}

	// Sanity check
	static assert(ProcessorEntry.sizeof == 20);

	// Defines a bus
	align(1) struct BusEntry {
		ubyte entryType;	// 1
		ubyte busID;
		char[6] busTypeString;
	}

	// Sanity check
	static assert(BusEntry.sizeof == 8);

	// Defines an IO APIC
	align(1) struct IOAPICEntry {
		ubyte entryType;	// 2
		ubyte ioAPICID;
		ubyte ioAPICVersion;
		ubyte ioAPICEnabledByte;
		uint ioAPICAddress;

		mixin(Bitfield!(ioAPICEnabledByte,
					"ioAPICEnabled", 1,
					"reserved", 7));
	}

	// Sanity check
	static assert(IOAPICEntry.sizeof == 8);

	// Defines a pin connection on the IO APIC
	align(1) struct IOInterruptEntry {
		ubyte entryType;	// 3
		ubyte interruptType;
		ubyte ioInterruptFlags;
		ubyte reserved;
		ubyte sourceBusID;
		ubyte sourceBusIRQ;
		ubyte destinationIOAPICID;
		ubyte destinationIOAPICIntin;

		mixin(Bitfield!(ioInterruptFlags,
					"po", 2,
					"el", 2,
					"reserved2", 4));
	}

	// Sanity check
	static assert(IOInterruptEntry.sizeof == 8);

	// Defines a pin connection on LIVT0 and LIVT1 on
	// the local APIC
	align(1) struct LocalInterruptEntry {
		ubyte entryType;	// 4
		ubyte interruptType;
		ubyte localInterruptFlags;
		ubyte reserved;
		ubyte sourceBusID;
		ubyte sourceBusIRQ;
		ubyte destinationLocalAPICID;
		ubyte destinationLocalAPICLintin;

		mixin(Bitfield!(localInterruptFlags,
					"po", 2,
					"el", 2,
					"reserved2",4));
	}


// -- Extended MP Configuration Table Entries -- //

	// The usage of these is unknown at this time

	align(1) struct SystemAddressSpaceMappingEntry {
		ubyte entryType;	// 128
		ubyte entryLength;	// 20
		ubyte busID;
		ubyte addressType;
		ulong addressBase;
		ulong addressLength;
	}

	// Sanity check
	static assert(SystemAddressSpaceMappingEntry.sizeof == 20);

	align(1) struct BusHierarchyDescriptorEntry {
		ubyte entryType;	// 129
		ubyte entryLength;	// 8
		ubyte busID;
		ubyte busInformation;
		ubyte parentBus;
		ubyte[3] reserved;

		mixin(Bitfield!(busInformation, "sd", 1, "reserved2", 7));
	}

	// Sanity check
	static assert(BusHierarchyDescriptorEntry.sizeof == 8);

	align(1) struct CompatibilityBusAddressSpaceModifierEntry {
		ubyte entryType;	// 130
		ubyte entryLength;	// 8
		ubyte busID;
		ubyte addressModifier;
		uint predefinedRangeList;

		mixin(Bitfield!(addressModifier, "pr", 1, "reserved", 7));
	}

	// Sanity check
	static assert(CompatibilityBusAddressSpaceModifierEntry.sizeof == 8);
}
