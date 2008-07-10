//this takes care of detecting multiple processors
module kernel.dev.mp;

import kernel.error;
import kernel.mem.vmem_structs;
import vmem = kernel.mem.vmem;
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

ErrorVal init()
{
	ubyte* virtualAddress = cast(ubyte*)global_mem_regions_t.extended_bios_data.virtual_start;
	ubyte* virtualEnd = virtualAddress + 0x400;
	kprintf!("start {x} :: end {x}\n")(virtualAddress,virtualEnd);
	mpFloatingPointer* tmp = scan(virtualAddress,virtualEnd);
	if(tmp == null)
	{
		virtualAddress = cast(ubyte*)0x9fc00+vmem.VM_BASE_ADDR;
		virtualEnd = virtualAddress + 0x400;
		kprintf!("start {x} :: end {x}\n")(virtualAddress,virtualEnd);
		tmp = scan(virtualAddress,virtualEnd);
		if(tmp == null)
		{
			//virtualAddress = cast(ubyte*)global_mem_regions_t.bios_data.virtual_start;
			//virtualEnd = virtualAddress + 0xffff;
			kprintf!("start {x} :: end {x}\n")(0xF0000+vmem.VM_BASE_ADDR,0xFFFFF+vmem.VM_BASE_ADDR);
			tmp = scan(cast(ubyte*)0x0+vmem.VM_BASE_ADDR,cast(ubyte*)0xFFFFF+vmem.VM_BASE_ADDR);
			if(tmp == null)
			{
				kprintf!("returning error\n")();
				return ErrorVal.CannotFindMPFloatingPointerStructure;
			}
		}
	}
	if(tmp == null)
	{
		kprintf!("not there")();
	}
	else
	{
		kprintf!("found it\n")();
	}
	mpInformation.pointerTable = tmp;
	printStruct(*(mpInformation.pointerTable));
//	kprintf!("{x}\n")(mpInformation.pointerTable.mpConfigPointer);
	return ErrorVal.Success;
}

mpFloatingPointer* scan(ubyte* start, ubyte* end)
{
	//kprintf!("in scan\n")();
	for(ubyte* currentByte = start; currentByte < end-3; currentByte++)
	{
		if(cast(char)*currentByte == '_')
		{
			//kprintf!("found _\n")();
			if(cast(char)*(currentByte+1) == 'M')
			{
				//kprintf!("found M\n")();
				if(cast(char)*(currentByte+2) == 'P')
				{
					//kprintf!("found P\n")();
					if(cast(char)*(currentByte+3) == '_')
					{
						kprintfln!("found at {x}")(currentByte);
						return cast(mpFloatingPointer*)currentByte;
					}
				}
			}
		}
	}
	return null;
}
