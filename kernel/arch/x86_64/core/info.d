/*
 * info.d
 *
 * This module contains a standardized method of storing the pin
 * configurations for the IO APIC and APIC and other information
 * necessary.
 *
 */

module kernel.arch.x86_64.core.info;

// This module supports the IO APIC
import kernel.arch.x86_64.core.ioapic;

struct Info
{
static:
public:

	// For redirection entries
	struct RedirectionEntry
	{
		ubyte destination = 0xFF;
		IOAPIC.InterruptType interruptType;
		IOAPIC.TriggerMode triggerMode;
		IOAPIC.InputPinPolarity inputPinPolarity;
		IOAPIC.DestinationMode destinationMode = IOAPIC.DestinationMode.Logical;
		IOAPIC.DeliveryMode deliveryMode;
		ubyte vector;
		ubyte sourceBusIRQ;
	}

	RedirectionEntry[256] redirectionEntries;
	uint numEntries;

	// For the IO APICs
	struct IOAPICInfo
	{
		// The ID, used when refering to the IO APIC
		ubyte ID;

		// The version information of the IO APIC
		ubyte ver;

		// Whether or not this IO APIC is enabled
		bool enabled;

		// Virtual address of the IO APIC register
		void* address;
	}

	IOAPICInfo[16] IOAPICs;
	uint numIOAPICs;

	// For the processors
	struct LAPICInfo
	{
		// The ID used to refer to the LAPIC
		ubyte ID;

		// The version information
		ubyte ver;

		// Whether or not we should use this processor
		bool enabled;
	}

	LAPICInfo[256] LAPICs;
	uint numLAPICs;

private:

}
