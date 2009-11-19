/*
 * tss.d
 *
 * This module implements the functionality behind the TSS, and
 * interfaces with the GDT. The TSS (Task State Segment) will
 * provide an interface to hardware switching.
 *
 * The x86_64 processor does not utilize hardware switching.
 * However, the TSS must be provided anyway. This is due to it
 * offering the functionality to provide a means of setting
 * the interrupt stack and also the IOPL (Input\Output
 * Privilege Level) for ports and ring 3 (Userland)
 *
 */

module kernel.arch.x86_64.core.tss;

// The TSS needs to be identified within a System Segment Descriptor
// within the GDT (Global Descriptor Table)
import kernel.arch.x86_64.core.gdt;

// Import ErrorVal
import kernel.core.error;
import kernel.core.kprintf;

struct TSS {
static:

	// Do the necessary work to allow the TSS to be installed.
	ErrorVal initialize() {
		// Add the TSS entry to the GDT
		GDT.setSystemSegment((tssBase >> 3), 0x67, (cast(ulong)&tss), GDT.SystemSegmentType.AvailableTSS, 0, true, false, false);

		return ErrorVal.Success;
	}

	// This function will install the TSS using the LTR (Load Task Register)
	// instruction for the architecture. Note: The GDT entry must be
	// available and present. It will be set to BusyTSS afterward.
	// To reset the TSS, you will need to reset the Segment Type to
	// AvailableTSS.
	void install() {
		kprintfln!("TSS BASE {}")(&tss);
		GDT.setSystemSegment((tssBase >> 3), 0x67, (cast(ulong)&tss), GDT.SystemSegmentType.AvailableTSS, 0, true, false, false);
		asm {
			ltr tssBase;
		}
	}

	// This function will set the stack for interrupts that call into
	// ring 0 (kernel mode)
	void setRSP0(void* stackPointer) {
		tss.rsp0 = cast(ulong)stackPointer;
	}

	void setIST(uint index, void* ptr) {
		tss.ist[index] = cast(ulong)ptr;
	}

private:

	ushort tssBase = 0x30;

	// This structure defines the TSS used by the architecture
	align(1) struct TaskStateSegment {
		uint reserved0;		// Reserved Space

		ulong rsp0;			// The stack to use for Ring 0 Interrupts
		ulong rsp1;			// For Ring 1 Interrupts
		ulong rsp2;			// For Ring 2 Interrupts

		ulong reserved1;	// Reserved Space

		ulong[7] ist;		// IST space

		ulong reserved2;	// Reserved Space
		ushort reserved3;	// Reserved Space

		ushort ioMap;		// IO Map Base Address (offset until IOPL Map)
	}

	TaskStateSegment tss;
}
