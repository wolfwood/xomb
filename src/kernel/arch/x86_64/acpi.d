module kernel.arch.x86_64.acpi;

import kernel.core.error;
import kernel.core.regions;
import kernel.core.log;
import kernel.core.util;

import kernel.arch.x86_64.vmem;
import kernel.arch.x86_64.lapic;
import kernel.arch.x86_64.ioapic;

import kernel.dev.vga;

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

// DESCRIPTOR HEADER:

align(1) struct DescriptorHeader
{
	ubyte[4] signature;	// should be the name of the table
	uint length;		// the length of the table (in bytes)
}

align(1) struct RSDP
{
	ubyte[8] signature;	// should be "RSD PTR "
	ubyte checksum;		// should allow the sum of all entries to be zero
	ubyte[6] OEMID;		// OEM supplied stringggg
	ubyte revision;		// The revision of this structure.
	uint ptrRSDT;		// Pointer (32bit) to the RSDT structure.
	uint len;			// length of the table (including header)
	ulong ptrXSDT;		// Pointer (64bit) to the XSDT structure.
	ubyte extChecksum;	// extended checksum (sum of all values including both checksums)

	ubyte[3] reserved;
}

align(1) struct RSDT
{
	ubyte[4] signature;	// should be "RSDT"
	uint len;			// length of the table (including all descriptor tables following)
	ubyte revision;		// = 1
	ubyte checksum;		// see RSDP
	ubyte[6] OEMID;		// see RSDP
	ulong OEMTableID;	// this is the manufacture model ID, must match the ID in the FADT
	uint OEMRevision;	// OEM revision of the table
	uint creatorID;		// Vender ID of utility that created the table
	uint creatorRevision;	// Revision of this utility

	// followed by (n) 32 bit addresses to other descriptor headers
}

align(1) struct XSDT
{
	ubyte[4] signature;	// should be "XSDT"
	uint len;			// length of the table (including all descriptor tables following)
	ubyte revision;		// = 1
	ubyte checksum;		// see RSDP
	ubyte[6] OEMID;		// see RSDP
	ulong OEMTableID;	// this is the manufacture model ID, must match the ID in the FADT
	uint OEMRevision;	// OEM revision of the table
	uint creatorID;		// Vender ID of utility that created the table
	uint creatorRevision;	// Revision of this utility

	// followed by (n) 64 bit addresses to other descriptor headers
}

// the Multiple Apic Description Table
align(1) struct MADT
{
	ubyte[4] signature;	// should be "APIC"
	uint len;			// length of the table
	ubyte revision;		// = 2
	ubyte checksum;		//
	ubyte[6] OEMID;		//
	ulong OEMTableID;	//
	uint OEMRevision;	//
	uint creatorID;		//
	uint creatorRevision;	//
	uint localAPICAddr;	// 32-bit physical address of the local APIC
	uint flags;			// flags (only one bit, bit 0: indicates the
						//			the system has n 8259 that must
						//			be disabled)

	// followed by a series of APIC structures //
}

align(1) struct entryLocalAPIC
{
	ubyte type;			// = 0
	ubyte len;			// = 8
	ubyte ACPICPUID;	// the ProcessorId for which this processor is
						//   listed in the ACPI Processor declaration
						//   operator.
	ubyte APICID;		// the processor's local APIC ID
	uint flags;			// flags (only one bit, bit 0: indicates whether
						//			the local APIC is useable)
}

align(1) struct entryIOAPIC
{
	ubyte type;			// = 1
	ubyte len;			// = 12
	ubyte IOAPICID;		// The IO APIC's ID
	ubyte reserved;		// = 0
	uint IOAPICAddr;	// The 32-bit physical address to access this I/O APIC
	uint globalSystemInterruptBase;	// The global system interrupt number where this IO APIC's interrupt inputs start.
										// The number of interrupt inputs is determined by the IO APIC's Max Redir Entry register.
}

align(1) struct entryInterruptSourceOverride
{
	ubyte type;			// = 2
	ubyte len;			// = 10
	ubyte bus;			// = 0 (ISA)
	ubyte source;		// IRQ
	uint globalSystemInterrupt;	// The GSI that this bus-relative irq will signal
	ushort flags;

	mixin(Bitfield!(flags, "po", 2, "el", 2, "reserved", 12));
}

// Designates the IO APIC interrupt inputs that should be enabled
// as non-maskable.  Any source that is non-maskable will not be
// available for use by devices
align(1) struct entryNMISource
{
	ubyte type;			// = 3
	ubyte len;			// = 8
	ushort flags;		// same as MPS INTI flags
	uint globalSystemInterrupt; // the GSI this NMI will signal

	mixin(Bitfield!(flags, "po", 2, "el", 2, "reserved", 12));
}

// This structure describes the Local APIC interrupt input (LINTn) that NMI
// is connected to for each of the processors in the system where such a
// connection exists.
align(1) struct entryLocalAPICNMI
{
	ubyte type;			// = 4
	ubyte len;			// = 6
	ubyte ACPICPUID;	// Processor ID corresponding to the ID listed in the Processor/Local APIC structure
	ushort flags;		// MPS INTI flags
	ubyte localAPICLINT;	// the LINTn input to which NMI is connected

	mixin(Bitfield!(flags, "polarity", 2, "trigger", 2, "reserved", 12));
}

align(1) struct entryLocalAPICAddressOverrideStructure
{
	ubyte type;			// = 5
	ubyte len;			// = 12
	ushort reserved;	// = 0
	ulong localAPICAddr;	// Physical address of the Local APIC. (or for Itanium systems, the starting address of the Processor Interrupt Block)
}

// Very similar to the IOAPIC entry.  If both IOAPIC and IOSAPIC exist, the
// IOSAPIC must be used.
align(1) struct entryIOSAPIC
{
	ubyte type;			// = 6
	ubyte len;			// = 16
	ubyte IOAPICID;		// IO SAPIC ID
	ubyte reserved;		// = 0
	uint globalSystemInterruptBase; // The GSI # where the IO SAPIC interrupt inputs start.
	ulong IOSAPICAddr;	// The 64-bit physical address to access this IO SAPIC.
}

// Again, similar to the Local APIC entry.
align(1) struct entryLocalSAPIC
{
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

//align(1) struct entryPlatformInterruptSource ... more IO SAPIC badness





struct ACPI
{

static:


	// Retained addresses:

	RSDP* ptrRSDP;

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

	acpiMPBase acpiMPInformation;






	ErrorVal init()
	{
		// ensure initialized values (paranoia)
		ptrRSDP = null;
		ptrRSDT = null;
		ptrXSDT = null;

		// find tables
		// if they are not found, return failure
		printLogLine("Finding the ACPI tables");

		// find the RSDP
		if (findRSDP() == ErrorVal.Fail)
		{
			printLogFail();
			return ErrorVal.Fail;
		}

		// check checksum
		// XXX: this will fail for legacy ACPI tables! (where the structure was only 20 bytes)
		if (!isChecksumValid(cast(ubyte*)ptrRSDP, RSDP.sizeof))
		{
			printLogFail();
			return ErrorVal.Fail;
		}
		printLogSuccess();

		printLogLine("Reading the ACPI tables");

		// read out the tables
		printStruct(*ptrRSDP);

		if (ptrRSDP.revision < 1)
		{
			printLogFail();
			return ErrorVal.Fail;
		}

		// which table should we use?
		// (lets assume the XSDT is there, it will be there if this is not a legacy RSDP... revision=1)
		ptrXSDT = cast(XSDT*)(cast(ubyte*)ptrRSDP.ptrXSDT + vMem.VM_BASE_ADDR);

		// read out this table
		//printStruct(*ptrXSDT);

		// validate the XSDT
		if (validateXSDT() == ErrorVal.Fail)
		{
			return ErrorVal.Fail;
		}

		// read in the descriptor tables following the XSDT
		findDescriptors();

		if (ptrMADT == null)
		{
			return ErrorVal.Fail;
		}

		//printStruct(*ptrMADT);

		// read the MADT
		readMADT();

		printLogSuccess();

		return ErrorVal.Success;
	}

	// search the BIOS memory range for "RSD PTR "
	// this will give us the RSDP Table (Root System Description Pointer)
	private ErrorVal findRSDP()
	{
		// Need to check the BIOS read-only memory space
		if (scan(cast(ubyte*)0xE0000 + vMem.VM_BASE_ADDR,
				 cast(ubyte*)0xFFFFF + vMem.VM_BASE_ADDR)
				  == ErrorVal.Success)
		{
			return ErrorVal.Success;
		}

		// Need to check the EBDA (Extended Bios Data Area)
		if (scan(global_mem_regions.extended_bios_data.virtual_start,
			 global_mem_regions.extended_bios_data.virtual_start +
			 global_mem_regions.extended_bios_data.length)
			  == ErrorVal.Success)
		{
			return ErrorVal.Success;
		}

		return ErrorVal.Fail;
	}

	private ErrorVal scan(ubyte* start, ubyte* end)
	{
		ubyte* currentByte = start;
		for( ; currentByte < end-8; currentByte++)
		{
			if (cast(char)*(currentByte+0) == 'R' &&
				cast(char)*(currentByte+1) == 'S' &&
				cast(char)*(currentByte+2) == 'D' &&
				cast(char)*(currentByte+3) == ' ' &&
				cast(char)*(currentByte+4) == 'P' &&
				cast(char)*(currentByte+5) == 'T' &&
				cast(char)*(currentByte+6) == 'R' &&
				cast(char)*(currentByte+7) == ' ')
			{
				ptrRSDP = cast(RSDP*)currentByte;
				return ErrorVal.Success;
			}
		}

		return ErrorVal.Fail;
	}

	private ErrorVal validateXSDT()
	{
		if (!isChecksumValid(cast(ubyte*)ptrXSDT, ptrXSDT.len))
		{
			return ErrorVal.Fail;
		}

		if (ptrXSDT.signature[0] == 'X' &&
			ptrXSDT.signature[1] == 'S' &&
			ptrXSDT.signature[2] == 'D' &&
			ptrXSDT.signature[3] == 'T')
		{
			return ErrorVal.Success;
		}

		return ErrorVal.Fail;
	}

	private void findDescriptors()
	{
		ulong* endByte = cast(ulong*)((cast(ubyte*)ptrXSDT) + ptrXSDT.len);
		ulong* curByte = cast(ulong*)(ptrXSDT + 1);

		for (; curByte < endByte; curByte++)
		{
			DescriptorHeader* curTable = cast(DescriptorHeader*)((*curByte) + vMem.VM_BASE_ADDR);

			if (curTable.signature[0] == 'A' &&
				curTable.signature[1] == 'P' &&
				curTable.signature[2] == 'I' &&
				curTable.signature[3] == 'C')
			{
				// this is the MADT table
				ptrMADT = cast(MADT*)curTable;
			}

			//printStruct(*curTable);
		}
	}

	private void readMADT()
	{
		ubyte* curByte = (cast(ubyte*)ptrMADT) + MADT.sizeof;
		ubyte* endByte = curByte + (ptrMADT.len - MADT.sizeof);

		// account for the length byte (trust me, it is an optimization)
		endByte--;

		while(curByte < endByte)
		{
			// read the type of structure it is
			switch(*curByte)
			{
				case 0: // Local APIC entry

					acpiMPInformation.localAPICs[acpiMPInformation.numLocalAPICs] = cast(entryLocalAPIC*)curByte;
					//printStruct(*acpiMPInformation.localAPICs[acpiMPInformation.numLocalAPICs]);
					acpiMPInformation.numLocalAPICs++;

					break;

				case 1: // IO APIC entry

					acpiMPInformation.IOAPICs[acpiMPInformation.numIOAPICs] = cast(entryIOAPIC*)curByte;
					//printStruct(*acpiMPInformation.IOAPICs[acpiMPInformation.numIOAPICs]);
					acpiMPInformation.numIOAPICs++;

					break;

				case 2: // Interrupt Source Overrides

					acpiMPInformation.intSources[acpiMPInformation.numIntSources] = cast(entryInterruptSourceOverride*)curByte;
					//printStruct(*acpiMPInformation.intSources[acpiMPInformation.numIntSources]);
					acpiMPInformation.numIntSources++;

					break;

				case 3: // NMI sources

					acpiMPInformation.NMISources[acpiMPInformation.numNMISources] = cast(entryNMISource*)curByte;
					//printStruct(*acpiMPInformation.NMISources[acpiMPInformation.numNMISources]);
					acpiMPInformation.numNMISources++;

					break;

				case 4: // LINTn Sources (Local APIC NMI Sources)

					acpiMPInformation.localAPICNMIs[acpiMPInformation.numLocalAPICNMIs] = cast(entryLocalAPICNMI*)curByte;
					//printStruct(*acpiMPInformation.localAPICNMIs[acpiMPInformation.numLocalAPICNMIs]);
					acpiMPInformation.numLocalAPICNMIs++;

					break;

				default: // ignore
					kprintfln!("unknown: {}")(*curByte);

					break;
			}

			curByte++;
			curByte += (*curByte) - 1; // skip this section (the length is the second byte)
		}
	}

	private bool isChecksumValid(ubyte* startAddr, uint length)
	{
		ubyte* endAddr = startAddr + length;
		int acc = 0;

		for (; startAddr < endAddr; startAddr++)
		{
			acc += *startAddr;
		}

		return ((acc &= 0xFF) == 0);
	}







	void initIOAPIC()
	{
		bool hasIMCR = false;

		// initialize IOAPIC
		IOAPIC.initFromACPI(acpiMPInformation.IOAPICs[0..acpiMPInformation.numIOAPICs], hasIMCR);

		// set redirection table entries
		IOAPIC.setRedirectionTableEntriesFromACPI(acpiMPInformation.intSources[0..acpiMPInformation.numIntSources],
												  acpiMPInformation.NMISources[0..acpiMPInformation.numNMISources]);
	}

	void initAPIC()
	{
		//start up APs and APIC bus
		LocalAPIC.init(cast(void*)ptrMADT.localAPICAddr);

		// tell the Local APIC of our intentions to use this table to start APs:
		LocalAPIC.tableType = LocalAPIC.TableType.ACPI;

		//LocalAPIC.startAPsFromACPI(acpiMPInformation.localAPICs[0..acpiMPInformation.numLocalAPICs]);
	}

	void startAPs()
	{
		uint myLocalId = LocalAPIC.getLocalAPICId();

		foreach(processor; acpiMPInformation.localAPICs[0..acpiMPInformation.numLocalAPICs])
		{
			if (processor.APICID == myLocalId)
			{
				continue;
			}

			if (!(processor.flags & 0x1))
			{
				continue;
			}

			LocalAPIC.startAP(processor.APICID);
		}
	}

	// will return which ioapic id this gsi is mapped to
	ubyte getIOAPICIDFromGSI(uint gsi)
	{
		foreach(ioapic; acpiMPInformation.IOAPICs)
		{
			if (gsi < ioapic.globalSystemInterruptBase)
			{
				continue;
			}

			// now we need to know the maximum pins this io apic has
			// ask the ioapic
			ubyte apicVer, apicMax;
			IOAPIC.getIOApicVersion(ioapic.IOAPICID, apicVer, apicMax);
			if (gsi < ioapic.globalSystemInterruptBase + apicMax + 1)
			{
				// yes
				return ioapic.IOAPICID;
			}
		}

		return 0xFF; // an invalid id, means failure
	}

	ubyte getIOAPICPinFromGSI(uint gsi)
	{
		foreach(ioapic; acpiMPInformation.IOAPICs)
		{
			if (gsi < ioapic.globalSystemInterruptBase)
			{
				continue;
			}

			ubyte apicVer, apicMax;
			IOAPIC.getIOApicVersion(ioapic.IOAPICID, apicVer, apicMax);
			if (gsi < ioapic.globalSystemInterruptBase + apicMax + 1)
			{
				return gsi - ioapic.globalSystemInterruptBase;
			}
		}

		return gsi;
	}
}
