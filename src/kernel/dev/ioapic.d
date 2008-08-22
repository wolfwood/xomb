module kernel.dev.ioapic;

import kernel.dev.vga;
import kernel.dev.mp;
import kernel.dev.lapic;

import kernel.mem.vmem;

import kernel.log;

struct IOAPIC
{
	static:

	void* ioApicAddress;

	void init(ref mpBase mpInformation, ioAPICEntry* ioApicEntry)
	{	
		printLogLine("Initializing IO APIC");
		ioApicAddress = cast(void*)(cast(ulong)ioApicEntry.ioAPICAddress + vMem.VM_BASE_ADDR);
		printLogSuccess();
	}

}
