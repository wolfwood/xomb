//this takes care of detecting multiple processors
module kernel.dev.mp;

import kernel.error;
import kernel.mem.vmem_structs;
import vmem = kernel.mem.vmem;
import kernel.core.util;
import kernel.vga;

import kernel.dev.lapic;

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
	apicRegisterSpace* apicRegisters;
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
	systemAddressSpaceMappingEntry*[maxSystemAddressSpaceMappingEntries] systemAddressSpaceMapping;
	busHierarchyDescriptorEntry*[maxBusHierarchyDescriptorEntries] busHierarchyDescriptors;
	compatibilityBusAddressSpaceModifierEntry*[maxCompatibilityBusAddressSpaceModifierEntries] compatibilityBusAddressSpaceModifiers;
}

private mpBase mpInformation;

ErrorVal init()
{
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
				return ErrorVal.CannotFindMPFloatingPointerStructure;
			}
		}
	}

	// Retain the MP Pointer Table
	mpInformation.pointerTable = tmp;
	//printStruct(*(mpInformation.pointerTable));

	// Obtain
	initConfigurationTable();

//	kprintf!("{x}\n")(mpInformation.pointerTable.mpConfigPointer);
	return ErrorVal.Success;
}

private void initConfigurationTable()
{
	// Obtain the MP Configuration Table, if it exists
	if (mpInformation.pointerTable.mpFeatures1 == 0)
	{
		// This means that the configuration table is present.
		kprintfln!("Configuration Table Present")();
		mpInformation.configTable = cast(mpConfigurationTable*)(vmem.VM_BASE_ADDR + cast(ulong)mpInformation.pointerTable.mpConfigPointer);
		//printStruct(*(mpInformation.configTable));
		if (!isChecksumValid(cast(ubyte*)mpInformation.configTable, mpInformation.configTable.baseTableLength))
		{
			kprintfln!("Configuration Table Checksum invalid!")();
			return;
		}
	}
	else
	{
		// This means that the configuration table is of the 'default'
		// set from the MP specs.
		kprintfln!("Configuration Table not present!")();

		// exit, do not continue to read entries, do not collect $200
		return;
	}

	initLocalApic(mpInformation);

	// We must map in the APIC register space into a separate kernel region
	
	//kprintfln!("APIC spurious vector: 0x{x}")(mpInformation.apicRegisters.spuriousIntVector);

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
			kprintfln!("corrupt MP config table")();
			return;					
		}
		switch(*curAddr)
		{
			case 0:
				if (mpInformation.processor_count != maxProcessorEntries)
				{
					mpInformation.processors[mpInformation.processor_count] = cast(processorEntry*)curAddr;
					kprintfln!("processor local apic id: {}")(mpInformation.processors[mpInformation.processor_count].localAPICID);
					kprintfln!("processor cpu flags: {x}")(mpInformation.processors[mpInformation.processor_count].cpuFlags);
					//printStruct(*mpInformation.processors[mpInformation.processor_count]);
					mpInformation.processor_count++;
				}
				curAddr += 20;
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
					kprintfln!("io apic id: {}")(mpInformation.ioApics[mpInformation.ioAPIC_count].ioAPICID);
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
			default:
				// WTF
				break;
		}
	}
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
