/*
 * ioapic.d
 *
 * This module implements the IO APIC
 *
 */

module kernel.arch.x86_64.core.ioapic;

// We need to know how to initialize the pins
import kernel.arch.x86_64.core.info;

// for mapping the register space
import kernel.arch.x86_64.core.paging;

// We need port io
import kernel.arch.x86_64.cpu;

// Import common kernel stuff
import kernel.core.error;
import kernel.core.log;
import kernel.core.kprintf;

struct IOAPIC
{
static:
public:

// -- Common Routines -- //

	// We assume that we set up IO APICs in order.
	// The first IO APIC to get called gets pin 0 to pin maxRedirEnt (inclusive)
	ErrorVal initialize() {
		kprintfln!("IOAPIC count: {}")(Info.numIOAPICs);
		return ErrorVal.Success;
	}

	ErrorVal unmaskIRQ(uint irq) {

		// no good (no irqs above 15)
		if (irq > 15) { return ErrorVal.Fail; }

		unmaskRedirectionTableEntry(irqToIOAPIC[irq], irqToPin[irq]);
		return ErrorVal.Success;
	}

	ErrorVal maskIRQ(uint irq) {

		// no good (no irqs above 15)
		if (irq > 15) { return ErrorVal.Fail; }

		maskRedirectionTableEntry(irqToIOAPIC[irq], irqToPin[irq]);
		return ErrorVal.Success;
	}

private:

// -- Register Structures -- //

	// The types of registers that can be accessed with the IO APIC
	enum Register {
		ID,
		VER,
		ARB,
		REDTBL0LO = 0x10,
		REDTBL0HI
	}

// -- Setup -- //

	void initUnit(ubyte ioAPICID, void* ioAPICAddress, bool hasIMCR) {

		// disable the IMCR
		if (hasIMCR) {
			// write 0x70 to port 0x22
			Cpu.ioOut!(ubyte, "0x22")(0x70);
			// write 0x01 to port 0x23
			Cpu.ioOut!(ubyte, "0x23")(0x01);
		}

		// map IOAPIC region
		void* IOAPICVirtAddr ;//= Paging.mapRegion(ioAPICAddress, 4096);

		// set the addresses for the data register and window
		ioApicRegisterSelect[ioAPICID] = cast(uint*)(IOAPICVirtAddr);
		ioApicWindowRegister[ioAPICID] = cast(uint*)(IOAPICVirtAddr + 0x10);
	}

// -- Register Read and Write -- //

	uint readRegister(uint ioApicID, Register reg) {
		volatile *(ioApicRegisterSelect[ioApicID]) = cast(uint)reg;
		return *(ioApicWindowRegister[ioApicID]);
	}

	void writeRegister(uint ioApicID, Register reg, in uint value) {
		volatile *(ioApicRegisterSelect[ioApicID]) = cast(uint)reg;
		volatile *(ioApicWindowRegister[ioApicID]) = value;
	}

	ubyte getID(uint ioApicID) {
		uint value = readRegister(ioApicID, Register.ID);
		value >>= 24;
		value &= 0xF;

		return cast(ubyte)value;
	}

	void setID(uint ioApicID, ubyte apicID) {
		uint value = cast(uint)apicID << 24;

		writeRegister(ioApicID, Register.ID, value);
	}

	void setRedirectionTableEntry(uint ioApicID, uint registerIndex,
			ubyte destinationField,
			Info.InterruptType intType,
			Info.TriggerMode triggerMode,
			Info.InputPinPolarity inputPinPolarity,
			Info.DestinationMode destinationMode,
			Info.DeliveryMode deliveryMode,
			ubyte interruptVector) {

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

		writeRegister(ioApicID, cast(Register)(Register.REDTBL0HI + (registerIndex*2)), valuehi);
		writeRegister(ioApicID, cast(Register)(Register.REDTBL0LO + (registerIndex*2)), valuelo);

	}

	void setRedirectionTableEntries() {

	}

	void unmaskRedirectionTableEntry(uint ioApicID, uint registerIndex) {
		// read former entry values
		uint lo = readRegister(ioApicID, cast(Register)(Register.REDTBL0LO + (registerIndex*2)));

		// set the value necessary
		// reset bit 0 of the hi word
		lo &= ~(1 << 16);

		// write it back
		writeRegister(ioApicID, cast(Register)(Register.REDTBL0LO + (registerIndex*2)), lo);
	}

	void maskRedirectionTableEntry(uint ioApicID, uint registerIndex) {
		// read former entry values
		uint lo = readRegister(ioApicID, cast(Register)(Register.REDTBL0LO + (registerIndex*2)));

		// set the value necessary
		// set bit 0 of the hi word
		lo |= (1 << 16);

		// write it back
		writeRegister(ioApicID, cast(Register)(Register.REDTBL0LO + (registerIndex*2)), lo);
	}

// -- IRQs and PINs -- //

	// stores which IO APIC pin a particular IRQ is connected.
	// irqToPin = the pin number
	// irqToIOAPIC = the io apic
	uint irqToPin[16] = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15];
	uint irqToIOAPIC[16] = [0];

	// This array will give the IO APIC that a particular pin is attached.
	uint pinToIOAPIC[256] = [0];

	// How many pins do we have?
	uint numPins = 0;

// -- The IO APIC Register Spaces -- //

	// This assumes that there can be only 16 IO APICs
	// These arrays are indexed by IO APIC ID
	// null will indicate the absense of an IO APIC

	uint* ioApicRegisterSelect[16];
	uint* ioApicWindowRegister[16];
	uint ioApicStartingPin[16]; // The starting pin index for this IO APIC

}
