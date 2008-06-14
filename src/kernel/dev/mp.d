//this takes care of detecting multiple processors
module kernel.dev.mp;

import kernel.error;
import kernel.mem.vmem_structs;
import kernel.core.util;
import kernel.vga;

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
	ubyte version_;
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
	ulong oemID;
	char[12] productID;
	uint oemTablePointer;
	ushort oemTableSize;
	ushort entryCount;
	uint addressOfLocalAPIC;
	ushort extendedTableLength;
	ubyte extendedTableChecksum;
}

//base mp configuration table entries
align(1) struct processorEntry {
	ubyte entryType = 0;
	ubyte localAPICID;
	ubyte localAPICVersion;
	ubyte cpuStuff;
	uint cpuSignature;
	uint cpuFeatureFlags;

	mixin(Bitfield!(cpuStuff, "cpuEnabledBit", 1, "cpuBootstrapProcessorBit", 1, "reserved", 6));
}

align(1) struct busEntry {
	ubyte entryType = 1;
	ubyte busID;
	char[6] busTypeString;
}

align(1) struct ioAPICEntry {
	ubyte entryType = 2;
	ubyte ioAPICID;
	ubyte ioAPICVersion;
	ubyte ioAPICEnabledByte;
	uint ioAPICAddress;

	mixin(Bitfield!(ioAPICEnabledByte, "ioAPICEnabled", 1, "reserved",7));
}

align(1) struct ioInterruptEntry {
	ubyte entryType = 3;
	ubyte interruptType;
	ubyte ioInterruptFlag;
	ubyte reserved;
	ubyte sourceBusID;
	ubyte sourceBusIRQ;
	ubyte destinationIOAPICID;
	ubyte destinationIOAPICIntin;

	mixin(Bitfield!(ioInterruptFlag, "po", 2, "el", 2, "reserved2",4));
}

align(1) struct localInterruptEntry {
	ubyte entryType = 4;
	ubyte interruptType;
	ubyte localInterruptFlag;
	ubyte reserved;
	ubyte sourceBusID;
	ubyte sourceBusIRQ;
	ubyte destinationLocalAPICID;
	ubyte destinationLocalAPICLintin;

	mixin(Bitfield!(localInterruptFlag, "po", 2, "el", 2, "reserved2",4));
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

struct mpBase {
	mpFloatingPointer* pointerTable;
	mpConfigurationTable* configTable;
	processorEntry*[maxProcessorEntries] processors;
	busEntry*[maxBusEntries] buses;
	ioAPICEntry*[maxIOAPICEntries] ioApics;
	ioInterruptEntry*[maxIOInterruptEntries] ioInterrupts;
	localInterruptEntry*[maxLocalInterruptEntries] localInterrupts;
	systemAddressSpaceMappingEntry*[maxSystemAddressSpaceMappingEntries] systemAddressSpaceMapping;
	busHierarchyDescriptorEntry*[maxBusHierarchyDescriptorEntries] busHierarchyDescriptors;
	compatibilityBusAddressSpaceModifierEntry*[maxCompatibilityBusAddressSpaceModifierEntries] compatibilityBusAddressSpaceModifiers;
}

private mpBase mpInformation;

ErrorVal init(mem_region extendedBiosRegion, mem_region systemBaseMemory, mem_region biosROM)
{
	ubyte* virtualAddress = cast(ubyte*)systemBaseMemory.virtual_start + (systemBaseMemory.physical_start + systemBaseMemory.length - 1024);
	ubyte* virtualEnd = virtualAddress + 1024;
	mpFloatingPointer* tmp = scan(virtualAddress,virtualEnd);
	if(tmp == null)
	{
		virtualAddress = cast(ubyte*)extendedBiosRegion.virtual_start + extendedBiosRegion.physical_start;
		virtualEnd = virtualAddress + 1024;
		tmp = scan(virtualAddress,virtualEnd);
		if(tmp == null)
		{
			virtualAddress = cast(ubyte*)biosROM.virtual_start + (biosROM.physical_start+0xF0000);
			virtualEnd = virtualAddress + 0xffff;
			tmp = scan(virtualAddress,virtualEnd);
			if(tmp == null)
			{
				return ErrorVal.CannotFindMPFloatingPointerStructure;
			}
		}
	}
	mpInformation.pointerTable = tmp;
	printStruct(*mpInformation.pointerTable);
	return ErrorVal.Success;
}

mpFloatingPointer* scan(ubyte* start, ubyte* end)
{
	mpFloatingPointer* result = null;
	for(ubyte* currentByte = start; currentByte < end-3; currentByte++)
	{
		if(*cast(char*)currentByte == '_')
		{
			if(*cast(char*)(currentByte-=1) == 'M')
			{
				if(*cast(char*)(currentByte+=2) == 'P')
				{
					if(*cast(char*)(currentByte+=3) == '_')
					{
						currentByte-=4;
						result = cast(mpFloatingPointer*)currentByte;
						break;
					}
					else
					{
						currentByte-=3;
					}
				}
				else
				{
					currentByte-=2;
				}
			}
			else
			{
				currentByte-=1;
			}
		}
	}
	return result;
}
