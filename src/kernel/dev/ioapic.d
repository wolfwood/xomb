module kernel.dev.ioapic;

import kernel.dev.vga;
import kernel.dev.mp;
import kernel.dev.lapic;

import kernel.mem.vmem;

import kernel.error;

import kernel.log;

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

	uint* ioApicRegisterSelect;
	uint* ioApicWindowRegister;

	void init(ref mpBase mpInformation, ioAPICEntry* ioApicEntry)
	{	
		printLogLine("Initializing IO APIC");

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

		ioApicRegisterSelect = cast(uint*)(IOAPICVirtAddr);
		ioApicWindowRegister = cast(uint*)(IOAPICVirtAddr + 0x10);

		ubyte apicVersion, maxRedirectionEntry;
		getIOApicVersion(apicVersion, maxRedirectionEntry);
		kdebugfln!(DEBUG_IOAPIC,"IO Ver: 0x{x} MaxRedirectEntry: 0x{x}")(apicVersion, maxRedirectionEntry);
		printLogSuccess();
	}

	void readRegister (IOAPICRegister reg, out uint value){
		volatile *(ioApicRegisterSelect) = cast(uint)reg;
		value = *(ioApicWindowRegister);
	}


	void writeRegister (IOAPICRegister reg, in uint value){
		volatile *(ioApicRegisterSelect) = cast(uint)reg;
		volatile *(ioApicWindowRegister) = value;
	}

	void getIOApicVersion (out ubyte apicVersion, out ubyte maxRedirectionEntry){
		uint value;
		readRegister(IOAPICRegister.IOAPICVER, value);
		apicVersion = (value & 0xFF);
		value >>= 16;
		maxRedirectionEntry = (value & 0xFF);
	}

	void setRedirectionTableEntry (uint registerIndex,
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
		
		writeRegister(cast(IOAPICRegister)(IOAPICRegister.IOREDTBL0HI + (registerIndex*2)), valuehi);
		writeRegister(cast(IOAPICRegister)(IOAPICRegister.IOREDTBL0LO + (registerIndex*2)), valuelo);
	}


       //Prints the information in the redirect table entries
       void printTableEntry(uint tableEntry) {
	 // Values that will be filled by readRegister
	 uint hi, lo;
	 // Make the calls
	 readRegister(cast(IOAPICRegister)(IOAPICRegister.IOREDTBL0HI + (tableEntry*2)), hi);
	 readRegister(cast(IOAPICRegister)(IOAPICRegister.IOREDTBL0LO + (tableEntry*2)), lo);

	 kdebugfln!(DEBUG_IOAPIC, "Hi-value: {}")(hi);
	 kdebugfln!(DEBUG_IOAPIC, "Lo-value: {}")(lo);


	 // Rebuild the whole thing
	 ulong whole = cast(ulong)hi << 32;
	 whole += lo;

	 kdebugfln!(DEBUG_IOAPIC, "Whole value = 0x{x}")(whole);

	 kdebugfln!(DEBUG_IOAPIC, "Destination field: {}")(whole & (0x8FUL << 56));
	 kdebugfln!(DEBUG_IOAPIC, "Interrupt mask: {}")(whole & (1 << 16));
	 kdebugfln!(DEBUG_IOAPIC, "Trigger mode: {}")(whole & (1 << 15));
	 kdebugfln!(DEBUG_IOAPIC, "Remote IRR: {}")(whole & (1 << 14));
	 kdebugfln!(DEBUG_IOAPIC, "Interrupt input pin polarity: {}")(whole & (1 << 13));
	 kdebugfln!(DEBUG_IOAPIC, "Delivery status {}")(whole & (1 << 12));
	 kdebugfln!(DEBUG_IOAPIC, "Destination mode: {}")(whole & (1 << 11));
	 kdebugfln!(DEBUG_IOAPIC, "Delivery mode: {}")(whole & (0xF << 10));
	 kdebugfln!(DEBUG_IOAPIC, "Interrupt vector: {}")(whole & 0x8F);
	 
       }


  

}
