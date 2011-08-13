/*
 * ioapic.d
 *
 * This module implements the IO APIC
 *
 */

module kernel.arch.x86_64.core.ioapic;

// We need to know how to initialize the pins
import kernel.arch.x86_64.core.info;
import kernel.arch.x86_64.core.lapic;

// for mapping the register space
import kernel.arch.x86_64.core.paging;

// For disabling PIC
import kernel.arch.x86_64.core.pic;

// We need port io
import architecture.cpu;

// Import common kernel stuff
import kernel.core.error;
import kernel.core.log;
import kernel.core.kprintf;

import user.types;


struct IOAPIC
{
static:
public:

// -- Common Routines -- //

	// We assume that we set up IO APICs in order.
	// The first IO APIC to get called gets pin 0 to pin maxRedirEnt (inclusive)
	ErrorVal initialize() {
		//kprintfln!("IOAPIC count: {}")(Info.numIOAPICs);

		// Disable PIC
		PIC.disable();

		// for all IOAPICs, init them
		for(int i = 0; i < Info.numIOAPICs; i++) {
			initUnit(Info.IOAPICs[i].ID, Info.IOAPICs[i].address, false);
		}

		// setting the redirection entries from the Info struct
		setRedirectionTableEntries();

		return ErrorVal.Success;
	}

	ErrorVal unmaskIRQ(uint irq, uint core) {

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

	ErrorVal unmaskPin(uint pin) {
		if (pin >= numPins) {
			// error: no pin available
			return ErrorVal.Fail;
		}

		uint IOAPICID = pinToIOAPIC[pin];
		uint IOAPICPin = pin - ioApicStartingPin[IOAPICID];

		maskRedirectionTableEntry(IOAPICID, IOAPICPin);

		return ErrorVal.Success;
	}

	ErrorVal maskPin(uint pin) {
		if (pin >= numPins) {
			// error: no pin available
			return ErrorVal.Fail;
		}

		uint IOAPICID = pinToIOAPIC[pin];
		uint IOAPICPin = pin - ioApicStartingPin[IOAPICID];

		maskRedirectionTableEntry(IOAPICID, IOAPICPin);

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

	void initUnit(ubyte ioAPICID, PhysicalAddress ioAPICAddress, bool hasIMCR) {

		// disable the IMCR
		if (hasIMCR) {
			// write 0x70 to port 0x22
			Cpu.ioOut!(ubyte, "0x22")(0x70);
			// write 0x01 to port 0x23
			Cpu.ioOut!(ubyte, "0x23")(0x01);
		}

		// map IOAPIC region
		//kprintfln!("IOAPIC Addr {x}")(ioAPICAddress);
		ubyte* IOAPICVirtAddr = Paging.mapRegion(ioAPICAddress, 4096).ptr;
		//kprintfln!("IOAPIC Addr {x}")(IOAPICVirtAddr);

		// set the addresses for the data register and window
		ioApicRegisterSelect[ioAPICID] = cast(uint*)(IOAPICVirtAddr);
		ioApicWindowRegister[ioAPICID] = cast(uint*)(IOAPICVirtAddr + 0x10);

		// get the number of redirection table entries
		ubyte apicVersion, maxRedirectionEntry;
		getIOApicVersion(ioAPICID, apicVersion, maxRedirectionEntry);

		// it will report one less
		maxRedirectionEntry++;

		//kprintfln!("Max Redirection Entry: {}")(maxRedirectionEntry);

		// keep track of which IOAPIC unit has control of which pins
		ioApicStartingPin[ioAPICID] = numPins;
		for(int i = 0; i < maxRedirectionEntry; i++) {
			pinToIOAPIC[i + numPins] = ioAPICID;
		}
		numPins += maxRedirectionEntry;
	}

// -- Register Read and Write -- //

	uint readRegister(uint ioApicID, Register reg) {
		/*volatile*/ uint* ptr = ioApicRegisterSelect[ioApicID];
		*ptr = cast(uint)reg;

		return *(ioApicWindowRegister[ioApicID]);
	}

	void writeRegister(uint ioApicID, Register reg, in uint value) {
		/*volatile*/ *(ioApicRegisterSelect[ioApicID]) = cast(uint)reg;
		/*volatile*/ *(ioApicWindowRegister[ioApicID]) = value;
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

	void getIOApicVersion(uint ioApicID, out ubyte apicVersion,
			out ubyte maxRedirectionEntry) {

		uint value = readRegister(ioApicID, Register.VER);

		apicVersion = (value & 0xFF);
		value >>= 16;

		maxRedirectionEntry = (value & 0xFF);
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

		valuelo |= (1 << 16);

		writeRegister(ioApicID, cast(Register)(Register.REDTBL0HI + (registerIndex*2)), valuehi);
		writeRegister(ioApicID, cast(Register)(Register.REDTBL0LO + (registerIndex*2)), valuelo);

	}

	void setRedirectionTableEntries() {
		//kprintfln!("setRedirectionTableEntries() : {}")(Info.numEntries);
		for(int i = 0; i < Info.numEntries && i < numPins; i++) {
			// get IOAPIC info and pin info for the specific IO APIC unit
			int IOAPICID = pinToIOAPIC[i];
			int IOAPICPin = i - ioApicStartingPin[IOAPICID];

			// set the table entry
			setRedirectionTableEntry(IOAPICID, IOAPICPin,
				Info.redirectionEntries[i].destination,
				Info.redirectionEntries[i].interruptType,
				Info.redirectionEntries[i].triggerMode,
				Info.redirectionEntries[i].inputPinPolarity,
				Info.redirectionEntries[i].destinationMode,
				Info.redirectionEntries[i].deliveryMode,
				Info.redirectionEntries[i].vector);

			// set IRQ stuff
			if (Info.redirectionEntries[i].sourceBusIRQ < 16) {
				irqToPin[Info.redirectionEntries[i].sourceBusIRQ] = i;
				irqToIOAPIC[Info.redirectionEntries[i].sourceBusIRQ] = IOAPICID;
			}
		}
		//kprintfln!("setRedirectionTableEntries() done")();
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
