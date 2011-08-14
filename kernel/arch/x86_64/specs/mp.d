/*
 * mp.d
 *
 * This module implements the Multiprocessor Specification
 *
 *
 * TODO: - Add comments and\or update the flags bitfields to
 *         cleaner and readible.
 *
 */

module kernel.arch.x86_64.specs.mp;

// Log information and errors
import kernel.core.error;
import kernel.core.log;

// Printing
import kernel.core.kprintf;

// Bitfield!()
import user.util;
import user.types;

// The Info struct holds all of the information we will enumerating
import kernel.arch.x86_64.core.info;
import kernel.arch.x86_64.core.ioapic;

// I need the virtual start for the memory mapping
import kernel.system.info;

// The struct for MP specification
struct MP {
static:
public:

	// This function will search for the MP tables.
	// It will return true when they have been found.
	ErrorVal findTable() {
		// These two arrays define the regions to look for the table (in physical addresses)
		static ubyte*[] checkStart	= [cast(ubyte*)0xf0000,	cast(ubyte*)0x9fc00];
		static ulong[] checkLen = [0xffff, 0x400];

		// This will be the temporary pointer to be used to find the table
		MPFloatingPointer* tmp;

		// For every region, scan for the table signature
		foreach(i,val; checkStart) {
			// scan() -- searches for the signature `_MP_`
			val += cast(ulong)System.kernel.virtualStart;

			tmp = scan(val, val + checkLen[i]);
			if (tmp !is null) {
				// The MP Table has been found, set
				// our reference pointer.
				mpFloating = tmp;

				// Return success.
				return ErrorVal.Success;
			}
		}

		// We have exhausted our searches, and failed.
		return ErrorVal.Fail;
	}

	// This function will utilize the table once it has been
	// found and store the information in a convenient place
	// for the IO APIC manager.
	ErrorVal readTable() {
		// Does the MP Configuration Table exist?
		if (mpFloating.mpFeatures1 == 0) {
			mpConfig = cast(MPConfigurationTable*)(cast(ulong)mpFloating.mpConfigPointer);

			// Make sure we can read it through the paging
			mpConfig = cast(MPConfigurationTable*)(cast(ubyte*)mpConfig + cast(ulong)System.kernel.virtualStart);

			// Check the checksum of the configuration table
			if (!isChecksumValid(cast(ubyte*)mpConfig, mpConfig.baseTableLength)) {
				return ErrorVal.Fail;
			}
		}
		else {
			// This means that the configuration table is of the 'default'
			// It is defined within the MP Specification

			// We do not support this as of yet.
			return ErrorVal.Fail;
		}

		Info.localAPICAddress = cast(PhysicalAddress)mpConfig.addressOfLocalAPIC;

		// We need to map in the APIC register space info a separate
		// kernel region.

		// --- //

		// We will obtain all other entry information

		ubyte* curAddr = cast(ubyte*)mpConfig;
		curAddr += MPConfigurationTable.sizeof;

		uint lastState = 0;

		for (uint i=0; i < mpConfig.entryCount; i++) {
			if (lastState > cast(int)(*curAddr)) {
				// Problem!

				// The MP Specification denotes that entries appear in order.
				// XXX: So this is weird. ... we will accept it for now ...
			}

			lastState = *curAddr;

			switch(lastState) {
				case 0: // Processor Entry

					// Set the Processor Entry in the Info struct
					ProcessorEntry* processor = cast(ProcessorEntry*)curAddr;

					Info.LAPICs[Info.numLAPICs].ID = processor.localAPICID;
					Info.LAPICs[Info.numLAPICs].ver = processor.localAPICVersion;
					Info.LAPICs[Info.numLAPICs].enabled = cast(bool)processor.cpuEnabledBit;

					// increment the count
					Info.numLAPICs++;

					curAddr += ProcessorEntry.sizeof;
					break;

				case 1: // Bus Entry

					curAddr += BusEntry.sizeof;
					break;

				case 2: // IO APIC Entry

					IOAPICEntry* ioapic = cast(IOAPICEntry*)curAddr;

					Info.IOAPICs[Info.numIOAPICs].ID = ioapic.ioAPICID;
					Info.IOAPICs[Info.numIOAPICs].ver = ioapic.ioAPICVersion;
					Info.IOAPICs[Info.numIOAPICs].enabled = cast(bool)ioapic.ioAPICEnabled;
					Info.IOAPICs[Info.numIOAPICs].address = cast(PhysicalAddress)ioapic.ioAPICAddress;

					// increment the count
					Info.numIOAPICs++;

					curAddr += IOAPICEntry.sizeof;
					break;

				case 3: // IO Interrupt Entry

					IOInterruptEntry* ioentry = cast(IOInterruptEntry*)curAddr;
					Info.redirectionEntries[Info.numEntries].sourceBusIRQ = ioentry.sourceBusIRQ;
					Info.redirectionEntries[Info.numEntries].vector = ioentry.destinationIOAPICIntin + 32;

					switch (ioentry.po)
					{
						case 0:
							// Conforms to the bus (dumb)
						case 1:
							// Active High
							Info.redirectionEntries[Info.numEntries].inputPinPolarity = Info.InputPinPolarity.HighActive;
							break;
						case 3:
							// Active Low
							Info.redirectionEntries[Info.numEntries].inputPinPolarity = Info.InputPinPolarity.LowActive;
							break;
						default:
							// undefined
							break;
					}

					switch (ioentry.el) {
						case 0:
							// Conforms to the bus (dumb!)
						case 1:
							// Edge-Triggered
							Info.redirectionEntries[Info.numEntries].triggerMode = Info.TriggerMode.EdgeTriggered;
							break;
						case 3:
							// Level-Triggered
							Info.redirectionEntries[Info.numEntries].triggerMode = Info.TriggerMode.LevelTriggered;
							break;
						default:
							// undefined
							break;
					}

					// XXX: switch(ioentry.interruptType) will cause a relocation error
					ulong intType = ioentry.interruptType;
					switch (intType)
					{
						case 0: // It is an INT (common)
							Info.redirectionEntries[Info.numEntries].deliveryMode = Info.DeliveryMode.LowestPriority;
							break;
						case 1: // It is a NMI
							Info.redirectionEntries[Info.numEntries].deliveryMode = Info.DeliveryMode.NonMaskedInterrupt;
							break;
						case 2: // It is a SMI
							Info.redirectionEntries[Info.numEntries].deliveryMode = Info.DeliveryMode.SystemManagementInterrupt;
							break;
						case 3: // It is an external interrupt (devices, etc)
							Info.redirectionEntries[Info.numEntries].deliveryMode = Info.DeliveryMode.ExtINT;
							break;
					}

					Info.numEntries++;

					curAddr += IOInterruptEntry.sizeof;
					break;

				case 4: // Local Interrupt Entry (LAPIC LIVT)

					curAddr += LocalInterruptEntry.sizeof;
					break;

				case 128: // System Address Space Mapping

					curAddr += SystemAddressSpaceMappingEntry.sizeof;
					break;

				case 129: // Bus Hierarchy Descriptor Entry

					curAddr += BusHierarchyDescriptorEntry.sizeof;
					break;

				case 130:

					curAddr += CompatibilityBusAddressSpaceModifierEntry.sizeof;
					break;

				default:

					// WTF

					// Unknown Entry type

					break;

			}
		}

		return ErrorVal.Success;
	}


private:

// -- The Local MP Floating Pointer -- //


	MPFloatingPointer* mpFloating;
	MPConfigurationTable* mpConfig;


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

	// Sanity check
	static assert(LocalInterruptEntry.sizeof == 8);


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


// -- Helper Functions -- //


	// This function will scan a section of memory looking for the telltale
	// _MP_ signature that signifies the start of the MP Floating Pointer
	MPFloatingPointer* scan(ubyte* start, ubyte* end)
	{
		for (ubyte* currentByte = start; currentByte < end - 3; currentByte++)
		{
			if (*(cast(uint*)currentByte) == *(cast(uint*)("_MP_"c.ptr)))
			{
				MPFloatingPointer* floatingTable = cast(MPFloatingPointer*)currentByte;
				if (floatingTable.length == 0x1
						&& floatingTable.mpVersion == 0x4
						&& isChecksumValid(currentByte, MPFloatingPointer.sizeof))
				{
					return floatingTable;
				}
			}
		}

		return null;
	}

	// This will check the byte checksum for a range of memory.
	// All checksums in the MP spec will result in 0 for success.
	bool isChecksumValid(ubyte* startAddr, uint length)
	{
		ubyte* endAddr = startAddr + length;
		int acc;
		for ( ; startAddr < endAddr; startAddr++)
		{
			acc += *startAddr;
		}

		return ((acc &= 0xff) == 0);
	}
}
