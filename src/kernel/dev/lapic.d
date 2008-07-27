// This module implements the abstraction for the Local APIC

module kernel.dev.lapic;

// Needs the ability to add virtual pages and ranges
import vmem = kernel.mem.vmem;

// Error codes
import kernel.error;

// Needs the MP Configuration Table
// and the MP information to get the addresses
import kernel.dev.mp;

// For support utils and printing
import kernel.core.util;
import kernel.vga;

align(1) struct apicRegisterSpace {
	/* 0000 */ uint reserved0;				ubyte[12] padding0;
	/* 0010 */ uint reserved1;				ubyte[12] padding1;
	/* 0020 */ uint localApicId;			ubyte[12] padding2;
	/* 0030 */ uint localApicIdVersion; 	ubyte[12] padding3;
	/* 0040 */ uint reserved2;				ubyte[12] padding4;
	/* 0050 */ uint reserved3;				ubyte[12] padding5;
	/* 0060 */ uint reserved4;				ubyte[12] padding6;
	/* 0070 */ uint reserved5;				ubyte[12] padding7;
	/* 0080 */ uint taskPriority;			ubyte[12] padding8;
	/* 0090 */ uint arbitrationPriority;	ubyte[12] padding9;
	/* 00a0 */ uint processorPriority;		ubyte[12] padding10;
	/* 00b0 */ uint EOI;					ubyte[12] padding11;
	/* 00c0 */ uint reserved6;				ubyte[12] padding12;
	/* 00d0 */ uint logicalDestination;		ubyte[12] padding13;
	/* 00e0 */ uint destinationFormat;		ubyte[12] padding14;
	/* 00f0 */ uint spuriousIntVector;		ubyte[12] padding15;
	/* 0100 */ uint isr0;					ubyte[12] padding16;
	/* 0110 */ uint isr1;					ubyte[12] padding17;
	/* 0120 */ uint isr2;					ubyte[12] padding18;
	/* 0130 */ uint isr3;					ubyte[12] padding19;
	/* 0140 */ uint isr4;					ubyte[12] padding20;
	/* 0150 */ uint isr5;					ubyte[12] padding21;
	/* 0160 */ uint isr6;					ubyte[12] padding22;
	/* 0170 */ uint isr7;					ubyte[12] padding23;
	/* 0180 */ uint tmr0;					ubyte[12] padding24;
	/* 0190 */ uint tmr1;					ubyte[12] padding25;
	/* 01a0 */ uint tmr2;					ubyte[12] padding26;
	/* 01b0 */ uint tmr3;					ubyte[12] padding27;
	/* 01c0 */ uint tmr4;					ubyte[12] padding28;
	/* 01d0 */ uint tmr5;					ubyte[12] padding29;
	/* 01e0 */ uint tmr6;					ubyte[12] padding30;
	/* 01f0 */ uint tmr7;					ubyte[12] padding31;
	/* 0200 */ uint irr0;					ubyte[12] padding32;
	/* 0210 */ uint irr1;					ubyte[12] padding33;
	/* 0220 */ uint irr2;					ubyte[12] padding34;
	/* 0230 */ uint irr3;					ubyte[12] padding35;
	/* 0240 */ uint irr4;					ubyte[12] padding36;
	/* 0250 */ uint irr5;					ubyte[12] padding37;
	/* 0260 */ uint irr6;					ubyte[12] padding38;
	/* 0270 */ uint irr7;					ubyte[12] padding39;
	/* 0280 */ uint errorStatus;			ubyte[12] padding40;
	/* 0290 */ uint reserved7;				ubyte[12] padding41;
	/* 02a0 */ uint reserved8;				ubyte[12] padding42;
	/* 02b0 */ uint reserved9;				ubyte[12] padding43;
	/* 02c0 */ uint reserved10;				ubyte[12] padding44;
	/* 02d0 */ uint reserved11;				ubyte[12] padding45;
	/* 02e0 */ uint reserved12;				ubyte[12] padding46;
	/* 02f0 */ uint reserved13;				ubyte[12] padding47;
	/* 0300 */ uint interruptCommandLo;		ubyte[12] padding48;
	/* 0310 */ uint interruptCommandHi;		ubyte[12] padding49;
	/* 0320 */ uint tmrLocalVectorTable;	ubyte[12] padding50;
	/* 0330 */ uint reserved14;				ubyte[12] padding51;
	/* 0340 */ uint performanceCounterLVT;	ubyte[12] padding52;
	/* 0350 */ uint lint0LocalVectorTable;	ubyte[12] padding53;
	/* 0360 */ uint lint1LocalVectorTable;	ubyte[12] padding54;
	/* 0370 */ uint errorLocalVectorTable;	ubyte[12] padding55;
	/* 0380 */ uint tmrInitialCount;		ubyte[12] padding56;
	/* 0390 */ uint tmrCurrentCount;		ubyte[12] padding57;
	/* 03a0 */ uint reserved15;				ubyte[12] padding58;
	/* 03b0 */ uint reserved16;				ubyte[12] padding59;
	/* 03c0 */ uint reserved17;				ubyte[12] padding60;
	/* 03d0 */ uint reserved18;				ubyte[12] padding61;
	/* 03e0 */ uint tmrDivideConfiguration;	ubyte[12] padding62;
}

void initLocalApic(ref mpBase mpInformation)
{
	// map the address space of the APIC
	ubyte* apicRange;

	// this function will set apicRange to the virtual address of the bios region
	if (vmem.map_range(
		cast(ubyte*)mpInformation.configTable.addressOfLocalAPIC,
		apicRegisterSpace.sizeof,
		apicRange) != ErrorVal.Success)
	{
		kprintfln!("error mapping apic register space! {x} ... {x}")(mpInformation.configTable.addressOfLocalAPIC, mpInformation.configTable.addressOfLocalAPIC + apicRegisterSpace.sizeof);
		return;
	}

	// get the apic address space, and add it to the base information
	mpInformation.apicRegisters = cast(apicRegisterSpace*)(apicRange);
	kprintfln!("local APIC address: {x}")(mpInformation.apicRegisters);

	enableLocalApic(mpInformation);
}

void enableLocalApic(ref mpBase mpInformation)
{
	// enable the APIC (just in case it is not enabled)
	mpInformation.apicRegisters.spuriousIntVector |= 0x100;
	kprintfln!("{}")(mpInformation.apicRegisters.spuriousIntVector);
	

}
