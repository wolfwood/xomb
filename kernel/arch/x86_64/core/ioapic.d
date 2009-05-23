/*
 * ioapic.d
 *
 * This module implements the IO APIC
 *
 */

module kernel.arch.x86_64.core.ioapic;

// We need to know how to initialize the pins
import kernel.arch.x86_64.core.info;

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
	ErrorVal initialize()
	{
		return ErrorVal.Success;
	}


// -- Common Structures -- //


private:


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


// -- Register Structures -- //


	// The types of registers that can be accessed with the IO APIC
	enum Register
	{
		ID,
		VER,
		ARB,
		REDTBL0LO = 0x10,
		REDTBL0HI
	}

}
