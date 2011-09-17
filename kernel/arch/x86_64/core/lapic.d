/*
 * lapic.d
 *
 * This module implements the Local APIC
 *
 */

module kernel.arch.x86_64.core.lapic;

import kernel.arch.x86_64.linker;

import architecture.mutex;
import architecture.cpu;

import kernel.arch.x86_64.core.paging;
import kernel.arch.x86_64.core.info;

import kernel.core.error;
import kernel.core.kprintf;
import kernel.core.log;

import kernel.system.info;

import user.types;


struct LocalAPIC {
static:
public:

	ErrorVal initialize() {
		initLocalApic(Info.localAPICAddress);

		install();

	//	startAPs();

		return ErrorVal.Success;
	}

	void startCores() {
		startAPs();
	}

	void install() {
		// Switch from PIC to APIC
		// Using IMCR registers
		Cpu.ioOut!(byte, "0x22")(0x70);
		Cpu.ioOut!(byte, "0x23")(0x01);

		// Set the Local Destination Register (LDR)
		apicRegisters.logicalDestination = (1 << getLocalAPICId()) << 24;

		// Set the Destination Format Register (DFR)
		// Enable the Flat Model for addressing Logical APIC IDs
		// Set Bits 28-31 to 1, All other bits are reserved and should be 1
		apicRegisters.destinationFormat = 0xFFFFFFFF;

		// Enable extINT, NMI interrupts
		// apicRegisters.lint0LocalVectorTable = 0x8700; // extINT
		// apicRegisters.lint1LocalVectorTable = 0x400; // NMI

		// Set task priority register (to not block any interrupts)
		apicRegisters.taskPriority = 0x0;

		// Enable the APIC (just in case it isn't already)
		apicRegisters.spuriousIntVector |= 0x10F;

		// LINT0 : ExtINT, Edge Triggered (0x8700) for Level)
		apicRegisters.lint0LocalVectorTable = 0x722; // extINT
		apicRegisters.lint1LocalVectorTable = 0x422; // NMI

		EOI();

		if (curCoreId == 0) {
			logicalIDToAPICId[0] = getLocalAPICId();
			APICIdToLogicalID[getLocalAPICId()] = 0;

			curCoreId++;
		}

	//	kprintfln!("Installed Core {}")(curCoreId);

		if (apLock.locked) {
			apLock.unlock();
		}
	}

	ErrorVal reportCore() {
		if (curCoreId == 0) {
			// This will get reported once the LocalAPIC has been
			// initialized above.
			return ErrorVal.Success;
		}

		logicalIDToAPICId[curCoreId] = getLocalAPICId();
		APICIdToLogicalID[getLocalAPICId()] = curCoreId;

		curCoreId++;

		return ErrorVal.Success;
	}

	uint identifier() {
		return APICIdToLogicalID[getLocalAPICId()];
	}

	uint id() {
		return getLocalAPICId();
	}

	void EOI() {
		apicRegisters.EOI = 0;
	}

private:

	uint curCoreId = 0;

	uint[256] logicalIDToAPICId = 0;
	uint[256] APICIdToLogicalID = 0;

	void initLocalApic(PhysicalAddress localAPICAddr) {
		ubyte* apicRange;

		ulong MSRValue = Cpu.readMSR(0x1B);
		MSRValue |= (1 << 11);
		Cpu.writeMSR(0x1B, MSRValue);

		// Map in the register space
		apicRegisters = cast(ApicRegisterSpace*)Paging.mapRegion(localAPICAddr, ApicRegisterSpace.sizeof);

		// Write the trampoline code where it needs to be

		uint trampolineLength = cast(ulong)LinkerScript.etrampoline - cast(ulong)LinkerScript.trampoline;
		ubyte* trampolineCode = cast(ubyte*)LinkerScript.trampoline + cast(ulong)System.kernel.virtualStart;

		// Map in the first megabyte of space
		ubyte* bootRange;
		bootRange = cast(ubyte*)Paging.mapRegion(null, trampolineLength);

		//kprintfln!("bootRange: {} trampolineLength: {} trampolineCode: {x} trampoline: {x} Kernel: {x}")(bootRange, trampolineLength, trampolineCode, LinkerScript.trampoline, System.kernel.start);

		for(uint i; i < trampolineLength; i++) {
			*bootRange = *trampolineCode;
			bootRange++;
			trampolineCode++;
		}
	//	bootRange[0..trampolineLength] = trampolineCode[0..trampolineLength];
		//kprintfln!("Trampoline copied")();
	}

	uint getLocalAPICId() {
		if (apicRegisters is null) {
			return 0;
		}

		uint ID = apicRegisters.localApicId;
		return ID >> 24;
	}

	void startAPs() {
		foreach(localAPIC; Info.LAPICs[0..Info.numLAPICs]) {
			if (localAPIC.enabled && localAPIC.ID != getLocalAPICId()) {
				startAP(localAPIC.ID);
			}
		}
	}

	Mutex apLock;

	void startAP(ubyte apicID) {
		Log.print("LocalAPIC: Starting AP");
		apLock.lock();

		ulong p;
		for (ulong o=0; o < 10000; o++) {
			p = o << 5 + 10;
		}

		sendINIT(apicID);

		for (ulong o = 0; o < 10000; o++) {
			p = o << 5 + 10;
		}

		sendStartup(apicID);

		for (ulong o = 0; o < 10000; o++) {
			p = o << 5 + 10;
		}

		sendStartup(apicID);

		for (ulong o = 0; o < 10000; o++) {
			p = o << 5 + 10;
		}

		// Wait for the AP to boot
		apLock.lock();
		apLock.unlock();
		Log.result(ErrorVal.Success);
	}

	enum DeliveryMode {
		Fixed,
		LowestPriority,
		SMI,
		Reserved,
		NonMaskedInterrupt,
		INIT,
		Startup,
	}

	void sendINIT(ubyte ApicID) {
		sendIPI(0, DeliveryMode.INIT, 0, 0, ApicID);
	}

	void sendStartup(ubyte ApicID) {
		sendIPI(0, DeliveryMode.Startup, 0, 0, ApicID);
	}

	// the destinationField is the apic ID of the processor to send the interrupt
	void sendIPI(ubyte vectorNumber, DeliveryMode dmode, bool destinationMode, ubyte destinationShorthand, ubyte destinationField) {
		// form the higher part first
		uint hiword = cast(uint)destinationField << 24;

		// set the high part
		apicRegisters.interruptCommandHi = hiword;

		// form the lower part now
		uint loword = cast(uint)vectorNumber;
		loword |= cast(uint)dmode << 8;

		if (destinationMode)
		{
			loword |= (1 << 11);
		}

		loword |= cast(uint)destinationShorthand << 18;

		// when this is set, the interrupt should be sent
		apicRegisters.interruptCommandLo = loword;
	}

	align(1) struct ApicRegisterSpace {
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

	ApicRegisterSpace* apicRegisters;
}
