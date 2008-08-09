//this takes care of detecting multiple processors
module kernel.dev.mp;

// log
import kernel.log;

import kernel.kmain;

import kernel.arch.select;

import kernel.error;
import kernel.mem.vmem_structs;
import vmem = kernel.mem.vmem;
import kernel.core.util;
import kernel.dev.vga;

import lapic = kernel.dev.lapic;

const ulong maxProcessorEntries = 255;
const ulong maxBusEntries = 255;
const ulong maxIOAPICEntries = 255;
const ulong maxIOInterruptEntries = 255;
const ulong maxLocalInterruptEntries = 255;
const ulong maxSystemAddressSpaceMappingEntries = 255;
const ulong maxBusHierarchyDescriptorEntries = 255;
const ulong maxCompatibilityBusAddressSpaceModifierEntries = 255;

align(1) struct mpFloatingPointer {
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

align(1) struct mpConfigurationTable {
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

//base mp configuration table entries

// entryType 0
align(1) struct processorEntry {
	ubyte entryType;
	ubyte localAPICID;
	ubyte localAPICVersion;
	ubyte cpuFlags;
	uint cpuSignature;
	uint cpuFeatureFlags;
	ubyte reservedBytes0;
	ubyte reservedBytes1;
	ubyte reservedBytes2;
	ubyte reservedBytes3;
	ubyte reservedBytes4;
	ubyte reservedBytes5;
	ubyte reservedBytes6;
	ubyte reservedBytes7;

	mixin(Bitfield!(cpuFlags, "cpuEnabledBit", 1, "cpuBootstrapProcessorBit", 1, "reserved", 6));
}

// entryType 1
align(1) struct busEntry {
	ubyte entryType;
	ubyte busID;
	char[6] busTypeString;
}

// entryType 2
align(1) struct ioAPICEntry {
	ubyte entryType;
	ubyte ioAPICID;
	ubyte ioAPICVersion;
	ubyte ioAPICEnabledByte;
	uint ioAPICAddress;

	mixin(Bitfield!(ioAPICEnabledByte, "ioAPICEnabled", 1, "reserved",7));
}

// entryType 3
align(1) struct ioInterruptEntry {
	ubyte entryType;
	ubyte interruptType;
	ubyte ioInterruptFlags;
	ubyte reserved;
	ubyte sourceBusID;
	ubyte sourceBusIRQ;
	ubyte destinationIOAPICID;
	ubyte destinationIOAPICIntin;

	mixin(Bitfield!(ioInterruptFlags, "po", 2, "el", 2, "reserved2",4));
}

// entryType 4
align(1) struct localInterruptEntry {
	ubyte entryType;
	ubyte interruptType;
	ubyte localInterruptFlags;
	ubyte reserved;
	ubyte sourceBusID;
	ubyte sourceBusIRQ;
	ubyte destinationLocalAPICID;
	ubyte destinationLocalAPICLintin;

	mixin(Bitfield!(localInterruptFlags, "po", 2, "el", 2, "reserved2",4));
}

//extended mp configuration table entries
align(1) struct systemAddressSpaceMappingEntry {
	ubyte entryType = 128;
	ubyte entryLength = 20;
	ubyte busID;
	ubyte addressType;
	ulong addressBase;
	ulong addressLength;
}

align(1) struct busHierarchyDescriptorEntry {
	ubyte entryType = 129;
	ubyte entryLength = 8;
	ubyte busID;
	ubyte busInformation;
	ubyte parentBus;
	ubyte[3] reserved;

	mixin(Bitfield!(busInformation, "sd", 1, "reserved2", 7));
}

align(1) struct compatibilityBusAddressSpaceModifierEntry {
	ubyte entryType = 130;
	ubyte entryLength = 8;
	ubyte busID;
	ubyte addressModifier;
	uint predefinedRangeList;

	mixin(Bitfield!(addressModifier, "pr", 1, "reserved", 7));
}

// contains all of the useful information about the multiprocessor
// capabilities of the system

// this is exposed to the kernel
struct mpBase {
	mpFloatingPointer* pointerTable;
	lapic.apicRegisterSpace* apicRegisters;
	mpConfigurationTable* configTable;
	uint processor_count;
	processorEntry*[maxProcessorEntries] processors;
	uint bus_count;
	busEntry*[maxBusEntries] busses;
	uint ioAPIC_count;
	ioAPICEntry*[maxIOAPICEntries] ioApics;
	uint ioInterrupt_count;
	ioInterruptEntry*[maxIOInterruptEntries] ioInterrupts;
	uint localInterrupt_count;
	localInterruptEntry*[maxLocalInterruptEntries] localInterrupts;
	uint systemAddressSpaceMapping_count;
	systemAddressSpaceMappingEntry*[maxSystemAddressSpaceMappingEntries] systemAddressSpaceMapping;
	uint busHierarchyDescriptor_count;
	busHierarchyDescriptorEntry*[maxBusHierarchyDescriptorEntries] busHierarchyDescriptors;
	uint compatibilityBusAddressSpaceModifier_count;
	compatibilityBusAddressSpaceModifierEntry*[maxCompatibilityBusAddressSpaceModifierEntries] compatibilityBusAddressSpaceModifiers;
}

private mpBase mpInformation;

ErrorVal init()
{
	printLogLine("Finding the MP Table");

	ubyte* virtualAddress;
	ubyte* virtualEnd;
	mpFloatingPointer* tmp = scan(cast(ubyte*)0xF0000+vmem.VM_BASE_ADDR,cast(ubyte*)0xFFFFF+vmem.VM_BASE_ADDR);
	if(tmp == null)
	{
		virtualAddress = cast(ubyte*)0x9fc00+vmem.VM_BASE_ADDR;
		virtualEnd = virtualAddress + 0x400;
		tmp = scan(virtualAddress,virtualEnd);
		if(tmp == null)
		{
			virtualAddress = cast(ubyte*)global_mem_regions.extended_bios_data.virtual_start;
			virtualEnd = virtualAddress + 0x400;
			tmp = scan(virtualAddress,virtualEnd);
			if(tmp == null)
			{
				printLogFail();
				return ErrorVal.CannotFindMPFloatingPointerStructure;
			}
		}
	}

	printLogSuccess();

	// Retain the MP Pointer Table
	mpInformation.pointerTable = tmp;

	printLogLine("Reading the Configuration Table");

	// Obtain
	if (initConfigurationTable() == ErrorVal.Success)
	{
		printLogSuccess();
	}
	else
	{
		printLogFail();
	}

	return ErrorVal.Success;
}

private ErrorVal initConfigurationTable()
{
	// Obtain the MP Configuration Table, if it exists
	if (mpInformation.pointerTable.mpFeatures1 == 0)
	{
		// This means that the configuration table is present.
		mpInformation.configTable = cast(mpConfigurationTable*)(vmem.VM_BASE_ADDR + cast(ulong)mpInformation.pointerTable.mpConfigPointer);
		if (!isChecksumValid(cast(ubyte*)mpInformation.configTable, mpInformation.configTable.baseTableLength))
		{
			return ErrorVal.Fail;
		}
	}
	else
	{
		// This means that the configuration table is of the 'default'
		// set from the MP specs.

		// exit, do not continue to read entries, do not collect $200
		return ErrorVal.Fail;
	}
	// We must map in the APIC register space into a separate kernel region

	// Obtain other entry information	
	ubyte* curAddr = cast(ubyte*)mpInformation.configTable;
	curAddr += mpConfigurationTable.sizeof;

	int lastState = 0;

	for (uint i=0; i< mpInformation.configTable.entryCount; i++)
	{		
		if (lastState <= cast(int)(*curAddr))
		{
			lastState = *curAddr;
		}
		else
		{
			// this is a problem
			return ErrorVal.Fail;
		}
		switch(*curAddr)
		{
			case 0:
				if (mpInformation.processor_count != maxProcessorEntries)
				{
					mpInformation.processors[mpInformation.processor_count] = cast(processorEntry*)curAddr;
					mpInformation.processor_count++;
				}
				curAddr += processorEntry.sizeof;
				break;
			case 1:
				if (mpInformation.bus_count != maxBusEntries)
				{
					mpInformation.busses[mpInformation.bus_count] = cast(busEntry*)curAddr;
					mpInformation.bus_count++;
				}
				curAddr += busEntry.sizeof;
				break;
			case 2:
				if (mpInformation.ioAPIC_count != maxIOAPICEntries)
				{
					mpInformation.ioApics[mpInformation.ioAPIC_count] = cast(ioAPICEntry*)curAddr;
					mpInformation.ioAPIC_count++;
				}
				curAddr += ioAPICEntry.sizeof;
				break;
			case 3:
				if (mpInformation.ioInterrupt_count != maxIOInterruptEntries)
				{
					mpInformation.ioInterrupts[mpInformation.ioInterrupt_count] = cast(ioInterruptEntry*)curAddr;
					mpInformation.ioInterrupt_count++;
				}
				curAddr += ioInterruptEntry.sizeof;
				break;
			case 4:
				if (mpInformation.localInterrupt_count != maxLocalInterruptEntries)
				{
					mpInformation.localInterrupts[mpInformation.localInterrupt_count] = cast(localInterruptEntry*)curAddr;
					mpInformation.localInterrupt_count++;
				}
				curAddr += localInterruptEntry.sizeof;
				break;
			case 128:
				if (mpInformation.systemAddressSpaceMapping_count != maxSystemAddressSpaceMappingEntries)
				{
					mpInformation.systemAddressSpaceMapping[mpInformation.systemAddressSpaceMapping_count] = cast(systemAddressSpaceMappingEntry*)curAddr;
					mpInformation.systemAddressSpaceMapping_count++;
				}
				curAddr += systemAddressSpaceMappingEntry.sizeof;
				break;
			case 129:
				if (mpInformation.busHierarchyDescriptor_count != maxBusHierarchyDescriptorEntries)
				{
					mpInformation.busHierarchyDescriptors[mpInformation.busHierarchyDescriptor_count] = cast(busHierarchyDescriptorEntry*)curAddr;
					mpInformation.busHierarchyDescriptor_count++;
				}
				curAddr += busHierarchyDescriptorEntry.sizeof;
				break;
			case 130:
				if (mpInformation.compatibilityBusAddressSpaceModifier_count != maxCompatibilityBusAddressSpaceModifierEntries)
				{
					mpInformation.compatibilityBusAddressSpaceModifiers[mpInformation.compatibilityBusAddressSpaceModifier_count] = cast(compatibilityBusAddressSpaceModifierEntry*)curAddr;
					mpInformation.compatibilityBusAddressSpaceModifier_count++;
				}
				curAddr += compatibilityBusAddressSpaceModifierEntry.sizeof;
				break;
			default:
				// WTF
				break;
		}
	}

	return ErrorVal.Success;
}

mpFloatingPointer* scan(ubyte* start, ubyte* end)
{
	for(ubyte* currentByte = start; currentByte < end-3; currentByte++)
	{
		if(cast(char)*currentByte == '_')
		{
			if(cast(char)*(currentByte+1) == 'M')
			{
				if(cast(char)*(currentByte+2) == 'P')
				{
					if(cast(char)*(currentByte+3) == '_')
					{
						mpFloatingPointer* floatingTable = cast(mpFloatingPointer*)currentByte;
						if (floatingTable.length == 0x1 && floatingTable.mpVersion == 0x4 && isChecksumValid(currentByte, mpFloatingPointer.sizeof))
						{
							return floatingTable;
						}
					}
				}
			}
		}
	}
	return null;
}

void initAPIC()
{
	// start up application processors and APIC bus
	lapic.init(mpInformation);
}

bool isChecksumValid(ubyte* startAddr, uint length)
{
	ubyte* endAddr = startAddr + length;
	int acc;
	for (; startAddr < endAddr; startAddr++)
	{
		acc += *startAddr;
	}

	return ((acc &= 0xFF) == 0);
}
