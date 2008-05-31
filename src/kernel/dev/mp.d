//this takes care of detecting multiple processors
module kernel.dev.mp;

import kernel.error;

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

	mixin(Bitfield!(polarityAndTrigger, "po", 2, "el", 2, "reserved2",6));
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

	mixin(Bitfield!(polarityAndTrigger, "po", 2, "el", 2, "reserved2",6));
}

//extended mp configuration table entries
align(1) struct systemAddressSpaceMapping {
	ubyte entryType = 128;
	ubyte entryLength = 20;
	ubyte busID;
	ubyte addressType;
	ulong addressBase;
	ulong addressLength;
}

align(1) struct busHierarchyDescriptor {
	ubyte entryType = 129;
	ubyte entryLength = 8;
	ubyte busID;
	ubyte busInformation;
	ubyte parentBus;
	ubyte[3] reserved;

	mixin(Bitfield!(busInformation, "sd", 1, "reserved2"));
}

align(1) struct compatibilityBusAddressSpaceModifier {
	ubyte entryType = 130;
	ubyte entryLength = 8;
	ubyte busID;
	ubyte addressModifier;
	uint predefinedRangeList;

	mixin(Bitfield!(addressModifier, "pr", 1, "reserved", 7));
}
