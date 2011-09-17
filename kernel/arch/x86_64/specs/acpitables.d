/*
 * acpitables.d
 *
 * This module contains the logic to find and parse the ACPI Tables
 *
 */

module kernel.arch.x86_64.specs.acpitables;

// Useful kernel imports
import kernel.core.error;
import kernel.core.kprintf;
import kernel.core.log;

// The Info struct holds all of the information we will enumerating
import kernel.arch.x86_64.core.info;
import kernel.arch.x86_64.core.paging;

// For memory map info
import kernel.system.info;

import user.util : Bitfield;
import user.types;

struct Tables {
static:
public:

	// For the multiprocessor initialization.
	// Will return true when the appropriate table is found.
	ErrorVal findTable() {
		if (findRSDP() == ErrorVal.Fail) {
			kprintfln!("Failed due to lack of RSDP")();
			return ErrorVal.Fail;
		}

		auto foo = cast(char*)ptrRSDP;

		// check checksum
		if (!isChecksumValid(cast(ubyte*)ptrRSDP, 20)) {
			kprintfln!("Failed due to incorrect checksum of RSDP (legacy): {}")(ptrRSDP);
			return ErrorVal.Fail;
		}

		if (!isLegacyRSDP) {
			if (!isChecksumValid(cast(ubyte*)ptrRSDP, ptrRSDP.len)) {
				kprintfln!("Failed due to incorrect checksum of RSDP: {}")(ptrRSDP);
				return ErrorVal.Fail;
			}
		}

		return ErrorVal.Success;
	}

	ErrorVal readTable() {
		// which table should we use?
		// (lets assume the XSDT is there, it will be there if this is not a legacy RSDP... revision=1)
		if (ptrRSDP.revision >= 1 && ptrRSDP.ptrXSDT != 0) {
			// Map in XSDT into kernel virtual memory space
			ptrXSDT = cast(XSDT*)Paging.mapRegion(cast(PhysicalAddress)ptrRSDP.ptrRSDT, RSDT.sizeof);

			// validate the XSDT
			if (validateXSDT() == ErrorVal.Fail) {
				kprintfln!("Failed due to incorrect XSDT")();
				return ErrorVal.Fail;
			}
		}
		else {
			// Map in RSDT into kernel virtual memory space
			ptrRSDT = cast(RSDT*)Paging.mapRegion(cast(PhysicalAddress)ptrRSDP.ptrRSDT, RSDT.sizeof);

			// validate the RSDT
			if (validateRSDT() == ErrorVal.Fail) {
				kprintfln!("Failed due to incorrect RSDT: {}")(ptrRSDT);
				return ErrorVal.Fail;
			}
		}

		// read in the descriptor tables following the XSDT/RSDT

		// We should use XSDT when available
		if (ptrXSDT !is null) {
			findDescriptors();
		}
		else {
			findDescriptors32();
		}

		if (ptrMADT is null) {
			kprintfln!("Failed due to the lack of a MADT")();
			return ErrorVal.Fail;
		}

		// initalize Redirection Entries to a 1-1 mapping
		if (initializeRedirectionEntries() != ErrorVal.Success) {
			return ErrorVal.Fail;
		}

		// read the MADT for redirection overrides
		return readMADT();
	}

private:

	// Retained addresses:

	RSDP* ptrRSDP;
	bool isLegacyRSDP = false;

	// main structures
	RSDT* ptrRSDT;
	XSDT* ptrXSDT;

	// system descriptors
	MADT* ptrMADT;

	static const uint maxEntries = 256;

	struct acpiMPBase {
		entryLocalAPIC*[maxEntries] localAPICs;
		uint numLocalAPICs;

		entryIOAPIC*[maxEntries] IOAPICs;
		uint numIOAPICs;

		entryInterruptSourceOverride*[maxEntries] intSources;
		uint numIntSources;

		entryNMISource*[maxEntries] NMISources;
		uint numNMISources;

		entryLocalAPICNMI*[maxEntries] localAPICNMIs;
		uint numLocalAPICNMIs;

		// XXX: maybe some day account for the IOSAPIC
	}

	// The ACPI is set up like so:

	// There is one RSDP table, which points to the RSDT and the XSDT
	// From the RSDP and XSDT, you can find most of the other tables

	// The RSDP has 32 bit addresses, and the XSDT has 64 bit addresses.
	// A compliant system MUST use the XSDT when it is provided.

	// We only need what we find necessary, so we only parse through until we find the table we want
	// However, we still need to understand how the other tables are specified.  They contain
	// simply a signature and a length at first (like any other chunk based format)

	// This means, we simply read those two pieces of information before choosing to do anything
	// further with it.
	// search the BIOS memory range for "RSD PTR "
	// this will give us the RSDP Table (Root System Description Pointer)

	ErrorVal findRSDP() {
		// Need to check the BIOS read-only memory space
		if (scan(cast(ubyte*)0xE0000 + cast(ulong)System.kernel.virtualStart,
					cast(ubyte*)0xFFFFF + cast(ulong)System.kernel.virtualStart)
				== ErrorVal.Success) {
			return ErrorVal.Success;
		}

		// Need to check BIOS reserved memory regions
		foreach(region; System.regionInfo[0..System.numRegions]) {
			if (region.type == RegionType.Reserved) {
				ErrorVal result = scan(region.virtualStart, region.virtualStart + region.length);
				if (result == ErrorVal.Success) {
					return ErrorVal.Success;
				}
			}
		}

		return ErrorVal.Fail;
	}

	ErrorVal scan(ubyte* start, ubyte* end) {
		ubyte* currentByte = start;
		for( ; currentByte < end-8; currentByte+=16) {
			if (cast(char)*(currentByte+0) == 'R' &&
					cast(char)*(currentByte+1) == 'S' &&
					cast(char)*(currentByte+2) == 'D' &&
					cast(char)*(currentByte+3) == ' ' &&
					cast(char)*(currentByte+4) == 'P' &&
					cast(char)*(currentByte+5) == 'T' &&
					cast(char)*(currentByte+6) == 'R' &&
					cast(char)*(currentByte+7) == ' ') {
				ptrRSDP = cast(RSDP*)currentByte;
				isLegacyRSDP = (ptrRSDP.revision == 0);
				return ErrorVal.Success;
			}
		}

		return ErrorVal.Fail;
	}

	ErrorVal validateRSDT() {
		if (!isChecksumValid(cast(ubyte*)ptrRSDT, ptrRSDT.len)) {
			return ErrorVal.Fail;
		}

		if (ptrRSDT.signature[0] == 'R' &&
				ptrRSDT.signature[1] == 'S' &&
				ptrRSDT.signature[2] == 'D' &&
				ptrRSDT.signature[3] == 'T') {
			return ErrorVal.Success;
		}

		return ErrorVal.Fail;
	}

	ErrorVal validateXSDT() {
		if (!isChecksumValid(cast(ubyte*)ptrXSDT, ptrXSDT.len)) {
			return ErrorVal.Fail;
		}

		if (ptrXSDT.signature[0] == 'X' &&
				ptrXSDT.signature[1] == 'S' &&
				ptrXSDT.signature[2] == 'D' &&
				ptrXSDT.signature[3] == 'T') {
			return ErrorVal.Success;
		}

		return ErrorVal.Fail;
	}

	void findDescriptors32() {
		uint* endByte = cast(uint*)((cast(ubyte*)ptrRSDT) + ptrRSDT.len);
		uint* curByte = cast(uint*)(ptrRSDT + 1);

		for (; curByte < endByte; curByte++) {
			DescriptorHeader* curTable = cast(DescriptorHeader*)Paging.mapRegion(cast(PhysicalAddress)(*curByte), MADT.sizeof);

			if (curTable.signature[0] == 'A' &&
					curTable.signature[1] == 'P' &&
					curTable.signature[2] == 'I' &&
					curTable.signature[3] == 'C') {
				// this is the MADT table
				ptrMADT = cast(MADT*)(cast(ubyte*)curTable);
			}
		}
	}

	void findDescriptors() {
		ulong* endByte = cast(ulong*)((cast(ubyte*)ptrXSDT) + ptrXSDT.len);
		ulong* curByte = cast(ulong*)(ptrXSDT + 1);

		for (; curByte < endByte; curByte++) {
			DescriptorHeader* curTable = cast(DescriptorHeader*)((*curByte) + cast(ulong)System.kernel.virtualStart);

			if (curTable.signature[0] == 'A' &&
					curTable.signature[1] == 'P' &&
					curTable.signature[2] == 'I' &&
					curTable.signature[3] == 'C') {
				// this is the MADT table
				ptrMADT = cast(MADT*)curTable;
			}
		}
	}

	// DESCRIPTOR HEADER:

	align(1) struct DescriptorHeader {
		char[4] signature;	// should be the name of the table

		// the length of the table (in bytes)
		uint length;
	}

	align(1) struct RSDP {
		char[8] signature;	// should be "RSD PTR "
		ubyte checksum;		// should allow the sum of all entries to be zero

		// OEM supplied string
		ubyte[6] OEMID;

		// The revision of this structure.
		ubyte revision;

		// Pointer (32bit) to the RSDT structure.
		uint ptrRSDT;

		// length of the table (including header)
		uint len;

		// Pointer (64bit) to the XSDT structure.
		ulong ptrXSDT;

		// Extended checksum (sum of all values including both checksums)
		ubyte extChecksum;

		ubyte[3] reserved;
	}

	align(1) struct RSDT {
		char[4] signature;	// should be "RSDT"

		// length of the table (including all descriptor tables following)
		uint len;

		ubyte revision;		// = 1
		ubyte checksum;		// see RSDP
		ubyte[6] OEMID;		// see RSDP

		// this is the manufacture model ID, must match the ID in the FADT
		ulong OEMTableID;

		// OEM revision of the table
		uint OEMRevision;

		// Vender ID of utility that created the table
		uint creatorID;

		// Revision of this utility
		uint creatorRevision;

		// followed by (n) 32 bit addresses to other descriptor headers
	}

	align(1) struct XSDT {
		char[4] signature;	// should be "XSDT"

		// length of the table (including all descriptor tables following)
		uint len;

		ubyte revision;		// = 1
		ubyte checksum;		// see RSDP
		ubyte[6] OEMID;		// see RSDP

		// This is the manufacture model ID, must match the ID in the FADT
		ulong OEMTableID;

		// OEM revision of the table
		uint OEMRevision;

		// Vender ID of utility that created the table
		uint creatorID;

		// Revision of this utility
		uint creatorRevision;

		// followed by (n) 64 bit addresses to other descriptor headers
	}

	// the Multiple Apic Description Table
	align(1) struct MADT {
		char[4] signature;	// should be "APIC"
		uint len;			// length of the table
		ubyte revision;		// = 2
		ubyte checksum;
		ubyte[6] OEMID;
		ulong OEMTableID;
		uint OEMRevision;
		uint creatorID;
		uint creatorRevision;

		// 32-bit physical address of the local APIC
		uint localAPICAddr;

		// flags (only one bit, bit 0: indicates the
		//			the system has n 8259 that must
		//			be disabled)
		uint flags;

		// followed by a series of APIC structures //
	}

	align(1) struct entryLocalAPIC {
		ubyte type;			// = 0
		ubyte len;			// = 8

		// the ProcessorId for which this processor is
		//   listed in the ACPI Processor declaration
		//   operator.
		ubyte ACPICPUID;

		// the processor's local APIC ID
		ubyte APICID;

		// flags (only one bit, bit 0: indicates whether
		//			the local APIC is useable)
		uint flags;
	}

	align(1) struct entryIOAPIC {
		ubyte type;			// = 1
		ubyte len;			// = 12

		// The IO APIC's ID
		ubyte IOAPICID;

		ubyte reserved;		// = 0

		// The 32-bit physical address to access this I/O APIC
		uint IOAPICAddr;

		// The global system interrupt number where this IO
		// APIC's interrupt inputs start. The number of
		// interrupt inputs is determined by the IO APIC's Max Redir Entry register.
		uint globalSystemInterruptBase;
	}

	align(1) struct entryInterruptSourceOverride {
		ubyte type;			// = 2
		ubyte len;			// = 10
		ubyte bus;			// = 0 (ISA)
		ubyte source;		// IRQ

		// The GSI that this bus-relative irq will signal
		uint globalSystemInterrupt;
		ushort flags;

		mixin(Bitfield!(flags, "po", 2, "el", 2, "reserved", 12));
	}

	// Designates the IO APIC interrupt inputs that should be enabled
	// as non-maskable.  Any source that is non-maskable will not be
	// available for use by devices
	align(1) struct entryNMISource {
		ubyte type;			// = 3
		ubyte len;			// = 8
		ushort flags;		// same as MPS INTI flags

		// the GSI this NMI will signal
		uint globalSystemInterrupt;

		mixin(Bitfield!(flags, "po", 2, "el", 2, "reserved", 12));
	}

	// This structure describes the Local APIC interrupt input (LINTn) that NMI
	// is connected to for each of the processors in the system where such a
	// connection exists.
	align(1) struct entryLocalAPICNMI {
		ubyte type;			// = 4
		ubyte len;			// = 6

		// Processor ID corresponding to the ID listed in the
		// Processor/Local APIC structure
		ubyte ACPICPUID;

		// MPS INTI flags
		ushort flags;

		// the LINTn input to which NMI is connected
		ubyte localAPICLINT;

		mixin(Bitfield!(flags, "polarity", 2, "trigger", 2, "reserved", 12));
	}

	align(1) struct entryLocalAPICAddressOverrideStructure {
		ubyte type;			// = 5
		ubyte len;			// = 12
		ushort reserved;	// = 0

		// Physical address of the Local APIC. (or for Itanium systems,
		// the starting address of the Processor Interrupt Block)
		ulong localAPICAddr;
	}

	// Very similar to the IOAPIC entry.  If both IOAPIC and IOSAPIC exist, the
	// IOSAPIC must be used.
	align(1) struct entryIOSAPIC {
		ubyte type;			// = 6
		ubyte len;			// = 16
		ubyte IOAPICID;		// IO SAPIC ID
		ubyte reserved;		// = 0

		// The GSI # where the IO SAPIC interrupt inputs start.
		uint globalSystemInterruptBase;

		// The 64-bit physical address to access this IO SAPIC.
		ulong IOSAPICAddr;
	}

	// Again, similar to the Local APIC entry.
	align(1) struct entryLocalSAPIC {
		ubyte type;			// = 7
		ubyte len;			// length in bytes
		ubyte ACPICPUID;	//
		ubyte localSAPICID;	//
		ubyte localSAPICEID;//
		ubyte[3] reserved;	// = 0
		uint flags;			//
		uint ACPICPUUID;	//

		// also has a null-terminated string associated with it //
	}

	ErrorVal initializeRedirectionEntries() {
		// Initialize redirection entries to a 1-1 mapping

		// The ACPI tables only show differences (that is, overrides) to
		// this 1-1 mapping with various default settings

		Info.numEntries = 16;
		for (int i = 0; i < 16; i++) {
			Info.redirectionEntries[i].destination = 0xff;
			Info.redirectionEntries[i].interruptType = Info.InterruptType.Masked;
			Info.redirectionEntries[i].triggerMode = Info.TriggerMode.EdgeTriggered;
			Info.redirectionEntries[i].inputPinPolarity = Info.InputPinPolarity.HighActive;
			Info.redirectionEntries[i].destinationMode = Info.DestinationMode.Logical;
			Info.redirectionEntries[i].deliveryMode = Info.DeliveryMode.LowestPriority;
			Info.redirectionEntries[i].sourceBusIRQ = i;
			Info.redirectionEntries[i].vector = 32 + i;
		}

		return ErrorVal.Success;
	}

	ErrorVal readMADT() {
		ubyte* curByte = (cast(ubyte*)ptrMADT) + MADT.sizeof;
		ubyte* endByte = curByte + (ptrMADT.len - MADT.sizeof);

		// account for the length byte (trust me, it is an optimization)
		endByte--;

		// Set LocalAPIC Address
		Info.localAPICAddress = cast(PhysicalAddress)ptrMADT.localAPICAddr;

		// For the overrides, read from the table

		while(curByte < endByte) {
			// read the type of structure it is
			switch(*curByte) {
				case 0: // Local APIC entry
					auto lapicInfo = cast(entryLocalAPIC*)curByte;

					// Get the ID
					Info.LAPICs[Info.numLAPICs].ID = lapicInfo.APICID;

					// Version is not given by ACPI tables.
					Info.LAPICs[Info.numLAPICs].ver = 0;

					// First bit indicates usability
					Info.LAPICs[Info.numLAPICs].enabled = (lapicInfo.flags & 0x1) == 0x1;

					Info.numLAPICs++;
					break;

				case 1: // IO APIC entry
					auto ioapicInfo = cast(entryIOAPIC*)curByte;

					// Get ID
					Info.IOAPICs[Info.numIOAPICs].ID = ioapicInfo.IOAPICID;

					// Version not given by ACPI tables.
					Info.IOAPICs[Info.numIOAPICs].ver = 0;

					// Assume it is enabled
					Info.IOAPICs[Info.numIOAPICs].enabled = true;

					// Get the IOAPIC address
					Info.IOAPICs[Info.numIOAPICs].address = cast(PhysicalAddress)ioapicInfo.IOAPICAddr;

					// increment the count
					Info.numIOAPICs++;
					break;

				case 2: // Interrupt Source Overrides
					auto nmiInfo = cast(entryInterruptSourceOverride*)curByte;

					Info.redirectionEntries[nmiInfo.globalSystemInterrupt].deliveryMode = Info.DeliveryMode.SystemManagementInterrupt;

					switch (nmiInfo.el) {
						default:
						case 0:
						case 1: // Edge Triggered
							Info.redirectionEntries[nmiInfo.globalSystemInterrupt].triggerMode = Info.TriggerMode.EdgeTriggered;
							break;
						case 2: // Level Triggered
							Info.redirectionEntries[nmiInfo.globalSystemInterrupt].triggerMode = Info.TriggerMode.LevelTriggered;
							break;
					}

					switch (nmiInfo.po) {
						default:
						case 0:
						case 1: // Active on a High
							Info.redirectionEntries[nmiInfo.globalSystemInterrupt].inputPinPolarity = Info.InputPinPolarity.HighActive;
							break;
						case 2: // Active on a Low
							Info.redirectionEntries[nmiInfo.globalSystemInterrupt].inputPinPolarity = Info.InputPinPolarity.LowActive;
							break;
					}
					break;

				case 3: // NMI sources
					auto nmiInfo = cast(entryNMISource*)curByte;

					Info.redirectionEntries[nmiInfo.globalSystemInterrupt].deliveryMode = Info.DeliveryMode.NonMaskedInterrupt;

					switch (nmiInfo.el) {
						default:
						case 0:
						case 1: // Edge Triggered
							Info.redirectionEntries[nmiInfo.globalSystemInterrupt].triggerMode = Info.TriggerMode.EdgeTriggered;
							break;
						case 2: // Level Triggered
							Info.redirectionEntries[nmiInfo.globalSystemInterrupt].triggerMode = Info.TriggerMode.LevelTriggered;
							break;
					}

					switch (nmiInfo.po) {
						default:
						case 0:
						case 1: // Active on a High
							Info.redirectionEntries[nmiInfo.globalSystemInterrupt].inputPinPolarity = Info.InputPinPolarity.HighActive;
							break;
						case 2: // Active on a Low
							Info.redirectionEntries[nmiInfo.globalSystemInterrupt].inputPinPolarity = Info.InputPinPolarity.LowActive;
							break;
					}

					break;

				case 4: // LINTn Sources (Local APIC NMI Sources)
					auto nmiInfo = cast(entryLocalAPICNMI*)curByte;
					break;

				default: // ignore
					kprintfln!("Unknown MADT entry: type: {}")(*curByte);

					break;
			}

			curByte++;
			curByte += (*curByte) - 1; // skip this section (the length is the second byte)
		}

		return ErrorVal.Success;
	}

	bool isChecksumValid(ubyte* startAddr, uint length) {
		ubyte* endAddr = startAddr + length;
		int acc = 0;

		for (; startAddr < endAddr; startAddr++) {
			acc += *startAddr;
		}

		return (acc & 0xFF) == 0;
	}
}
