/*
 * info.d
 *
 * This module contains a standardized method of storing the pin
 * configurations for the IO APIC and APIC and other information
 * necessary.
 *
 */

module kernel.arch.x86_64.core.info;

import user.types;


struct Info {
static:
public:

	enum DestinationMode {
		Physical,
		Logical
	}

	enum InputPinPolarity {
		HighActive,
		LowActive
	}

	enum TriggerMode {
		EdgeTriggered,
		LevelTriggered
	}

	enum InterruptType {
		Unmasked,
		Masked
	}

	enum DeliveryMode {
		Fixed,
		LowestPriority,
		SystemManagementInterrupt,
		NonMaskedInterrupt = 0x4,
		INIT,
		ExtINT = 0x7
	}

	// For redirection entries
	struct RedirectionEntry {
		ubyte destination = 0xFF;
		InterruptType interruptType;
		TriggerMode triggerMode;
		InputPinPolarity inputPinPolarity;
		DestinationMode destinationMode = DestinationMode.Logical;
		DeliveryMode deliveryMode;
		ubyte vector;
		ubyte sourceBusIRQ;
	}

	RedirectionEntry[256] redirectionEntries;
	uint numEntries;

	// For the IO APICs
	struct IOAPICInfo {
		// The ID, used when refering to the IO APIC
		ubyte ID;

		// The version information of the IO APIC
		ubyte ver;

		// Whether or not this IO APIC is enabled
		bool enabled;

		// address of the IO APIC register
		PhysicalAddress address;
	}

	IOAPICInfo[16] IOAPICs;
	uint numIOAPICs;

	// For the processors
	struct LAPICInfo {
		// The ID used to refer to the LAPIC
		ubyte ID;

		// The version information
		ubyte ver;

		// Whether or not we should use this processor
		bool enabled;
	}

	// The address of the apic registers
	PhysicalAddress localAPICAddress;

	LAPICInfo[256] LAPICs;
	uint numLAPICs;

private:
}
