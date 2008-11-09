module kernel.arch.x86_64.ioapic;

import kernel.dev.vga;

import kernel.arch.x86_64.mp;
import kernel.arch.x86_64.lapic;
import kernel.arch.x86_64.vmem;
import kernel.arch.x86_64.pic;

import kernel.core.error;

import kernel.core.log;

import config;

enum IOAPICRegister{
	IOAPICID,
	IOAPICVER,
	IOAPICARB,
	IOREDTBL0HI = 0x10,
	IOREDTBL0LO,
	IOREDTBL1HI,
	IOREDTBL1LO,
	IOREDTBL2HI,
	IOREDTBL2LO,
	IOREDTBL3HI,
	IOREDTBL3LO,
	IOREDTBL4HI,
	IOREDTBL4LO,
	IOREDTBL5HI,
	IOREDTBL5LO,
	IOREDTBL6HI,
	IOREDTBL6LO,
	IOREDTBL7HI,
    	IOREDTBL7LO,
	IOREDTBL8HI,
    	IOREDTBL8LO,
	IOREDTBL9HI,        
	IOREDTBL9LO,
	IOREDTBL10HI,
   	IOREDTBL10LO,
	IOREDTBL11HI,
	IOREDTBL11LO,
	IOREDTBL12HI,
	IOREDTBL12LO,
	IOREDTBL13HI,
	IOREDTBL13LO,
	IOREDTBL14HI,
	IOREDTBL14LO,
	IOREDTBL15HI,
	IOREDTBL15LO,
	IOREDTBL16HI,
	IOREDTBL16LO,
	IOREDTBL17HI,
	IOREDTBL17LO,
	IOREDTBL18HI,
	IOREDTBL18LO,
	IOREDTBL19HI,
	IOREDTBL19LO,
	IOREDTBL20HI,
	IOREDTBL20LO,
	IOREDTBL21HI,
	IOREDTBL21LO,
	IOREDTBL22HI,
	IOREDTBL22LO,
	IOREDTBL23HI,
	IOREDTBL23LO
}

enum IOAPICDestinationMode{
	Physical,
	Logical
}

enum IOAPICInputPinPolarity{
	HighActive,
	LowActive
}

enum IOAPICTriggerMode{
	EdgeTriggered,
	LevelTriggered
}

enum IOAPICInterruptType{
	Unmasked,
	Masked
}

enum IOAPICDeliveryMode{
	Fixed,
	LowestPriority,
	SystemManagementInterrupt,
	NonMaskedInterrupt = 0x4,
	INIT,
	ExtINT = 0x7
}

struct IOAPIC
{
	static:

	// all possible virtual addresses for io apics
	// indexed by the IO APIC ID
	// (assuming only 16 can exist)

	// null : indicates the absense of an io apic

	uint* ioApicRegisterSelect[16];
	uint* ioApicWindowRegister[16];

	void init(ioAPICEntry* ioApicEntry)
	{	
		printLogLine("Initializing IO APIC");

		//PIC.disable();
		PIC.enableAll();

		// redirect 8259a to IOAPIC (precaution)
		// write 0x70 to port 0x22
		// write 0x01 to port 0x23
		asm {
			"movb $0x70, %%al";
			"outb %%al, $0x22";		
		}
		asm {
			"movb $0x01, %%al";
			"outb %%al, $0x23";
		}

		// map IOAPIC region
		ubyte* IOAPICVirtAddr;

		// this function will set IOAPICVirtAddr to the virtual address of the bios region
		if (vMem.mapRange(
			cast(ubyte*)ioApicEntry.ioAPICAddress,
			4096,
			IOAPICVirtAddr) != ErrorVal.Success)
		{
			return;
		}

		ioApicRegisterSelect[ioApicEntry.ioAPICID] = cast(uint*)(IOAPICVirtAddr);
		ioApicWindowRegister[ioApicEntry.ioAPICID] = cast(uint*)(IOAPICVirtAddr + 0x10);

		ubyte apicVersion, maxRedirectionEntry;
		getIOApicVersion(ioApicEntry.ioAPICID, apicVersion, maxRedirectionEntry);
		kdebugfln!(DEBUG_IOAPIC,"IO Ver: 0x{x} MaxRedirectEntry: 0x{x}")(apicVersion, maxRedirectionEntry);

		setIOApicID(ioApicEntry.ioAPICID, ioApicEntry.ioAPICID);

		ubyte apicID;
		getIOApicID(ioApicEntry.ioAPICID, apicID);
		kprintfln!("IO APIC ID: {}")(apicID);


		// print IO APIC Table
		// for each redirection entry

		uint valuehi;
		uint valuelo;
		for (int i = 0; i < 0 * maxRedirectionEntry; i++)
		{
			readRegister(ioApicEntry.ioAPICID, cast(IOAPICRegister)(IOAPICRegister.IOREDTBL0HI + (i*2)), valuehi);
			readRegister(ioApicEntry.ioAPICID, cast(IOAPICRegister)(IOAPICRegister.IOREDTBL0LO + (i*2)), valuelo);
		
			// get delivery mode
			valuelo >>= 8;
			int dmode = valuelo & 0x07;
			valuelo >>= 7;
			int type = valuelo & 0x01;	

			kprintfln!("PIN: {} DMODE: {x} TYPE: {x}")(i, dmode, type);
		}

		printLogSuccess();
	}

	void initFromMP(ioAPICEntry*[] ioApics)
	{
		foreach(ioapic; ioApics)
		{
			init(ioapic);
		}
	}

	void setRedirectionTableEntriesFromMP(ioInterruptEntry*[] ioEntries)
	{
		IOAPICTriggerMode trigMode;
		IOAPICInterruptType intMasked = IOAPICInterruptType.Unmasked;
		IOAPICInputPinPolarity intPolarity;
		IOAPICDeliveryMode intType;

		foreach(ioentry; ioEntries)
		{
			kprintf!("IRQ {} to INT {} in IOAPIC Pin {} .. ")(ioentry.sourceBusIRQ, 35, ioentry.destinationIOAPICIntin);
			// get trigger mode
			if (ioentry.el == 0)
			{
				// depends on the bus type (this is stupid, but ok)
				trigMode = IOAPICTriggerMode.EdgeTriggered;
			}			
			else if (ioentry.el == 1)
			{
				// edge triggered
				trigMode = IOAPICTriggerMode.EdgeTriggered;
			}
			else if (ioentry.el == 3)
			{
				// level triggered
				trigMode = IOAPICTriggerMode.LevelTriggered;
			}
			else
			{
				// invalid, undefined
				trigMode = IOAPICTriggerMode.EdgeTriggered;
			}

			//get polarity
			if (ioentry.po == 0)
			{
				// depends on bus type
				intPolarity = IOAPICInputPinPolarity.HighActive;
			}
			else if (ioentry.po == 1)
			{
				// active high
				intPolarity = IOAPICInputPinPolarity.HighActive;
			}
			else if (ioentry.po == 3)
			{
				// active low
				intPolarity = IOAPICInputPinPolarity.LowActive;
			}
			else 
			{
				// invalid, undefined
				intPolarity = IOAPICInputPinPolarity.HighActive;
			}

			// interpret type
			if (ioentry.interruptType == 0) // INT (common)
			{
				intType = IOAPICDeliveryMode.Fixed;
			}
			else if (ioentry.interruptType == 1) // NMI
			{
				intType = IOAPICDeliveryMode.NonMaskedInterrupt;
			}
			else if (ioentry.interruptType == 2) // SMI
			{
				intType = IOAPICDeliveryMode.SystemManagementInterrupt;
			}
			else if (ioentry.interruptType == 3) // ExtINT
			{
				intType = IOAPICDeliveryMode.ExtINT;
			}

			// XXX: set to hardcoded values... uncomment to match
			// TODO: have values for 'bus conformity' ... I'd say just steal the linux values for this
			setRedirectionTableEntry(ioentry.destinationIOAPICID, ioentry.destinationIOAPICIntin, 
				// destination
				0xFF,
				// interrupt type
				IOAPICInterruptType.Unmasked,
				// trigger mode (edge, level)
				IOAPICTriggerMode.EdgeTriggered, // trigMode,
				// pin polarity
				IOAPICInputPinPolarity.HighActive, // intPolarity,
				// destination mode
				IOAPICDestinationMode.Logical,
				// delivery mode
				IOAPICDeliveryMode.Fixed, // intType,
				// vector
				cast(ubyte)(33 + ioentry.destinationIOAPICIntin)
			);
		}
	}

	void readRegister (uint ioApicID, IOAPICRegister reg, out uint value){
		volatile *(ioApicRegisterSelect[ioApicID]) = cast(uint)reg;
		value = *(ioApicWindowRegister[ioApicID]);
	}


	void writeRegister (uint ioApicID, IOAPICRegister reg, in uint value){
		volatile *(ioApicRegisterSelect[ioApicID]) = cast(uint)reg;
		volatile *(ioApicWindowRegister[ioApicID]) = value;
	}

	void getIOApicVersion (uint ioApicID, out ubyte apicVersion, out ubyte maxRedirectionEntry){
		uint value;
		readRegister(ioApicID, IOAPICRegister.IOAPICVER, value);
		apicVersion = (value & 0xFF);
		value >>= 16;
		maxRedirectionEntry = (value & 0xFF);
	}

	void getIOApicID (uint ioApicID, out ubyte apicID)
	{
		uint value;
		readRegister(ioApicID, IOAPICRegister.IOAPICID, value);
		value >>= 24;
		value &= 0x0F;

		apicID = cast(ubyte)value;
	}

	void setIOApicID(uint ioApicID, ubyte apicID)
	{
		uint value;
		value = cast(uint)apicID << 24;

		writeRegister(ioApicID, IOAPICRegister.IOAPICID, value);
	}

	void setRedirectionTableEntry (uint ioApicID, uint registerIndex,
		ubyte destinationField,
		IOAPICInterruptType intType,
		IOAPICTriggerMode triggerMode,
		IOAPICInputPinPolarity inputPinPolarity,
		IOAPICDestinationMode destinationMode,
		IOAPICDeliveryMode deliveryMode,
		ubyte interruptVector)
	{
		int valuehi = destinationField;
		valuehi <<= 24;
		
		int valuelo = intType;
		valuelo <<= 1;
		valuelo |= triggerMode;
		valuelo <<= 2;
		valuelo |= inputPinPolarity;
		valuelo <<= 2;
		valuelo |= destinationMode;
		valuelo <<= 3;
		valuelo |= deliveryMode;
		valuelo <<= 8;
		valuelo |= interruptVector;
		
		writeRegister(ioApicID, cast(IOAPICRegister)(IOAPICRegister.IOREDTBL0HI + (registerIndex*2)), valuehi);
		writeRegister(ioApicID, cast(IOAPICRegister)(IOAPICRegister.IOREDTBL0LO + (registerIndex*2)), valuelo);
	}

	//Prints the information in the redirect table entries
	void printTableEntry(uint ioApicID, uint tableEntry) 
	{
		// Values that will be filled by readRegister
		uint hi, lo;
		// Make the calls
		readRegister(ioApicID, cast(IOAPICRegister)(IOAPICRegister.IOREDTBL0HI + (tableEntry*2)), hi);
		readRegister(ioApicID, cast(IOAPICRegister)(IOAPICRegister.IOREDTBL0LO + (tableEntry*2)), lo);

		kdebugfln!(DEBUG_IOAPIC, "Hi-value: {}")(hi);
		kdebugfln!(DEBUG_IOAPIC, "Lo-value: {}")(lo);


		// Rebuild the whole thing
		ulong whole = cast(ulong)hi;
		whole <<= 32;
		whole += cast(ulong)lo;

		kdebugfln!(DEBUG_IOAPIC, "Interrupt vector: {}")(whole & 0xFF);
		whole >>= 8;
		kdebugfln!(DEBUG_IOAPIC, "Delivery Mode: {}")(whole & 0x7);
		whole >>= 3;
		kdebugfln!(DEBUG_IOAPIC, "Destination Mode: {}")(whole & 0x1);
		whole >>= 1;
		kdebugfln!(DEBUG_IOAPIC, "Delivery Status: {}")(whole & 0x1);
		whole >>= 1;
		kdebugfln!(DEBUG_IOAPIC, "Interrupt input pin polarity: {}")(whole & 0x1);
		whole >>= 1;
		kdebugfln!(DEBUG_IOAPIC, "Remote IRR: {}")(whole & 0x1);
		whole >>= 1;
		kdebugfln!(DEBUG_IOAPIC, "Trigger Mode: {}")(whole & 0x1);
		whole >>= 1;
		kdebugfln!(DEBUG_IOAPIC, "Interrupt Mask: {}")(whole & 0x1);
		whole >>= 40;
		kdebugfln!(DEBUG_IOAPIC, "Destination Field: {}")(whole & 0xFF);
	 
       }


  
}
