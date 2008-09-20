module kernel.dev.keyboard;

import kernel.dev.ioapic;

void kbd_init() {
	
	IOAPIC.setRedirectionTableEntry(1, 1, IOAPICInterruptType.Unmasked, 
									IOAPICTriggerMode.EdgeTriggered, 
									IOAPICInputPinPolarity.HighActive,
									IOAPICDestinationMode.Physical,
									IOAPICDeliveryMode.LowestPriority,
									1);


}