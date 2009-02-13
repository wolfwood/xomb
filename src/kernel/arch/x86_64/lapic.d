// This module implements the abstraction for the Local APIC

module kernel.arch.x86_64.lapic;


import kernel.dev.vga;

// Needs the ability to add virtual pages and ranges
import kernel.arch.x86_64.vmem;

// log
import kernel.log;

// need addresses of trampoline region
import kernel.arch.x86_64.globals;

// Error codes
import kernel.core.error;

import kernel.arch.x86_64.idt;
import kernel.arch.x86_64.gdt;
import kernel.arch.x86_64.syscall;
import kernel.arch.x86_64.acpi;
import kernel.arch.locks;

// for logging
import kernel.core.log;

// Needs the MP Configuration Table
// and the MP information to get the addresses
import kernel.arch.x86_64.mp;

// Needs MSR functions in Cpu
import kernel.arch.x86_64.cpu;

// For support utils and printing
import kernel.core.util;

// For reporting the cpu to the scheduler
import kernel.environment.scheduler;

// For debug config values
import config;


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

struct LocalAPIC
{

	static:

	private apicRegisterSpace* apicRegisters;

	void init(void* localAPICAddr)
	{
		printLogLine("Initializing Local APIC");
		initLocalApic(localAPICAddr);
		printLogSuccess();

		printLogLine("Enabling Local APIC");
		enableLocalApic();
		printLogSuccess();

		//Interrupts.setCustomHandler(35, &timerProc);

		//startAPs();

		//initTimer();

		// THIS WILL SEND AN INTERRUPT AND FIRE THE ISR
		//sendIPI(35, DeliveryMode.Fixed, 0, 0, getLocalAPICId());
	}

	void initLocalApic(void* localAPICAddr)
	{
		// map the address space of the APIC
		ubyte* apicRange;

		// enable the local apic with an MSR
		ulong MSRValue = Cpu.readMSR(0x1B);
		MSRValue |= (1 << 11);
		Cpu.writeMSR(0x1B, MSRValue);

		// this function will set apicRange to the virtual address of the bios region
		if (vMem.mapRange(
			cast(ubyte*)localAPICAddr,
			apicRegisterSpace.sizeof,
			apicRange) != ErrorVal.Success)
		{
			//kprintfln!("error mapping apic register space! {x} ... {x}")(mpInformation.configTable.addressOfLocalAPIC, mpInformation.configTable.addressOfLocalAPIC + apicRegisterSpace.sizeof);
			return;
		}

		ubyte* firstSpace;

		// map first megabyte
		if (vMem.mapRange(
			cast(ubyte*)0,
			0x100000,
			firstSpace) != ErrorVal.Success)
		{
			//kprintfln!("error mapping initial megabyte of space")();
			return;
		}

		//kprintfln!("Trampoline Code: {x} - {x}")(trampolineStart, trampolineEnd);

		// copy trampoline code to first megabyte

		ubyte* trampolinePointer = Globals.trampolineStart;
		ubyte* trampolineDestination = firstSpace;
		for ( ; trampolinePointer < Globals.trampolineEnd ; trampolinePointer++, trampolineDestination++)
		{
			(*trampolineDestination) = (*trampolinePointer);
		}

		// get the apic address space, and add it to the base information
		apicRegisters = cast(apicRegisterSpace*)(apicRange);
		//kprintfln!("local APIC address: {x}")(apicRegisters);

		kdebugfln!(DEBUG_LAPIC, "local APIC version: 0x{x}")(apicRegisters.localApicIdVersion & 0xFF);
		kdebugfln!(DEBUG_LAPIC, "number of LVT Entries: {}")((apicRegisters.localApicIdVersion >> 16) + 1);
	}

	void enableLocalApic()
	{
		// switch from PIC to APIC
		// using IMCR registers
		Cpu.ioOut!(byte, "22h")(0x70);
		Cpu.ioOut!(byte, "23h")(0x01);

		// set the Logical Destination Register (LDR)
		apicRegisters.logicalDestination = (1 << getLocalAPICId()) << 24;

		// set the Destination Format Register (DFR)
		// enable the Flat Model for addressing Logical APIC IDs
		// set bits 28-31 to 1, all other bits are reserved and should be 1
		apicRegisters.destinationFormat = 0xFFFFFFFF;

		// enable extINT, NMI interrupts
		//apicRegisters.lint0LocalVectorTable = 0x08700; //extINT
		//apicRegisters.lint1LocalVectorTable = 0x00400; //NMI

		// set task priority register (to not block any interrupts)
		apicRegisters.taskPriority = 0x0;

		// enable the APIC (just in case it is not enabled)
		apicRegisters.spuriousIntVector |= 0x10F;
		//kprintfln!("{}")(apicRegisters.spuriousIntVector);

		// enable extINT, NMI interrupts (by setting to unmasked, bit 16 = 1)

		// LINT0 : ExtINT, Edge Triggered (0x008700 for Level)
		apicRegisters.lint0LocalVectorTable = 0x00722; //extINT

		// LINT1 : NMI (Non-Masked Interrupts)
		apicRegisters.lint1LocalVectorTable = 0x00422; //NMI

		//kprintfln!("DFR: {x} LDR: {x}")(apicRegisters.destinationFormat, apicRegisters.logicalDestination);

		EOI();
	}

	kmutex apLock;


	void initTimer()
	{
		uint timerValue;

		// periodic
		timerValue |= (1 << 17);

		// masked or nonmasked
		//timerValue |= (1 << 16);

		// delivery status
		//timerValue |= (1 << 12); // 0: idle, 1: send pending

		// vector
		timerValue |= 35;
		apicRegisters.tmrDivideConfiguration |= 0b1011;

		apicRegisters.tmrLocalVectorTable = timerValue;
		apicRegisters.tmrInitialCount = 1000;
	}

	// EOI (end of interrupt)
	// acknowledge an interrupt on the local apic
	// really only important for level-triggered stuff,
	// but doesn't hurt to just to it anyway
	void EOI()
	{
		apicRegisters.EOI = 0;
	}

	void timerProc(InterruptStack* s)
	{
		kprintfln!("Timer!!!", false)();

		apicRegisters.EOI = 0;

	}

	uint getLocalAPICId()
	{
		return apicRegisters.localApicId >> 24;
	}

	void startAPsFromMP(processorEntry*[] processors)
	{
		uint myLocalId = getLocalAPICId();

		// go through the list of AP APIC IDs
		foreach (processor; processors)
		{
			//kprintfln!("cpu...startAP {}")(processor.localAPICID);
			// This next line will prevent the CPU from initializing itself in the middle
			// of running.  This will prevent us from totally failing while booting :P
			if(processor.localAPICID == myLocalId)
				continue;

			startAP(processor.localAPICID);
		}

		//kprintfln!("startAPs done")();
	}

	void startAPsFromACPI(entryLocalAPIC*[] processors)
	{
		uint myLocalId = getLocalAPICId();

		foreach (processor; processors)
		{
			// Again, do not allow the BSP to restart
			if (processor.APICID == myLocalId)
				continue;

			// check device enabled flag
			if (!(processor.flags & 0x1))
				continue;

			startAP(processor.APICID);
		}
	}

	void startAP(ubyte apicID)
	{
		apLock.lock();

		// success is printed by the AP in apExec()
		printLogLine("Initializing CPU");

		// Universal Algorithm

		ulong p;
		for (ulong o=0; o < 10000; o++)
		{
			p = o << 5 + 10;
		}
		kdebugfln!(DEBUG_LAPIC, "cpu: send INIT")();

		sendINIT(apicID);

		for (ulong o=0; o < 10000; o++)
		{
			p = o << 5 + 10;
		}

		kdebugfln!(DEBUG_LAPIC, "cpu: send Startup")();

		sendStartup(apicID);

		for (ulong o=0; o < 10000; o++)
		{
			p = o << 5 + 10;
		}

		kdebugfln!(DEBUG_LAPIC, "cpu: send Startup... again")();

		sendStartup(apicID);

		for (ulong o=0; o < 10000; o++)
		{
			p = o << 5 + 10;
		}

		kdebugfln!(DEBUG_LAPIC, "cpu: waiting for ap")();

		apLock.lock();
		apLock.unlock();

		kdebugfln!(DEBUG_LAPIC, "cpu: wait over")();

	}




	enum DeliveryMode
	{
		Fixed,
		LowestPriority,
		SMI,
		Reserved,
		NonMaskedInterrupt,
		INIT,
		Startup,
	}

	void sendINIT(ubyte ApicID)
	{
		sendIPI(0, DeliveryMode.INIT, 0, 0, ApicID);
	}

	void sendStartup(ubyte ApicID)
	{
		sendIPI(0, DeliveryMode.Startup, 0, 0, ApicID);
	}

	// the destinationField is the apic ID of the processor to send the interrupt
	void sendIPI(ubyte vectorNumber, DeliveryMode dmode, bool destinationMode, ubyte destinationShorthand, ubyte destinationField)
	{
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

}

extern (C) void apEntry()
{
	kdebugfln!(DEBUG_APENTRY, "AP - Entry")();

	// set paging

	void* pl4 = (cast(void*)vMem.pageLevel4.ptr) - vMem.VM_BASE_ADDR;

	asm {
		"movq %0, %%rax" :: "o" pl4;
		"movq %%rax, %%cr3";
	}

	// run common boot
	// this sets up GDT, IDT and SYSCALL
	Cpu.boot();

	// enable local apic
	LocalAPIC.enableLocalApic();

	kdebugfln!(DEBUG_APENTRY, "AP - Boot of CPU Complete")();

/*	volatile void* apStack;
	volatile void* apStackSupplementary;

	if (vMem.getKernelPage(apStack) == ErrorVal.Success)
	{
		// apStack is the address of a 4KB page
		// within the kernel space

		for (int i = 1; i<4; i++)
		{
			if (vMem.getKernelPage(apStackSupplementary) != ErrorVal.Success)
			{
				// Crap!
				kdebugfln!(DEBUG_APENTRY, "Error - Cannot Allocate Stack")();
			}
		}
	}
	else
	{
		kprintfln!("Error - Cannot Allocate Stack")();
	}

	kdebugfln!(DEBUG_APENTRY, "AP - Stack Space Allocated")();

	// Set Stack

	asm {

		"movq %0, %%rsp" :: "o" apStack;

	}*/

	// set the new stack
	asm {
		"movq $" ~ Itoa!(vMem.KERNEL_STACK) ~ ", %%rsp";
	}

	apExec();
}

void apExec()
{
	//kprintfln!("EXEC")();
	//LocalAPIC.sendIPI(35, LocalAPIC.DeliveryMode.LowestPriority, true, 0, 0x1);

	printLogSuccess();

	LocalAPIC.apLock.unlock();

	Scheduler.cpuReady(Cpu.info.ID);
}
