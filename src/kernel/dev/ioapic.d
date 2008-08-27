module kernel.dev.ioapic;

import kernel.dev.vga;
import kernel.dev.mp;
import kernel.dev.lapic;

import kernel.mem.vmem;

import kernel.log;

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
		ioApicRegisterSelect = cast(uint*)(cast(ulong)ioApicEntry.ioAPICAddress + vMem.VM_BASE_ADDR);
		ioApicWindowRegister = ioApicRegisterSelect + 1;
		printLogSuccess();
	}

	void readRegister (IOAPICRegister reg, out uint value){
		(*ioApicRegisterSelect) = cast(uint)reg;
		value = (*ioApicWindowRegister);
	}

	void writeRegister (IOAPICRegister reg, in uint value){
		(*ioApicRegisterSelect) = cast(uint)reg;
		(*ioApicWindowRegister) = value;
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

}
