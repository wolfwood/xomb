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
import kernel.arch.x86_64.core.descriptor;

import architecture.cpu;
import architecture.vm;

import kernel.mem.pageallocator;

import kernel.arch.x86_64.core.paging;

// Import ErrorVal
import kernel.core.error;
import kernel.core.kprintf;

struct TSS {
static:

	// Do the necessary work to allow the TSS to be installed.
	ErrorVal initialize() {
		// Add the TSS entry to the GDT
		return ErrorVal.Success;
	}

	// This function will install the TSS using the LTR (Load Task Register)
	// instruction for the architecture. Note: The GDT entry must be
	// available and present. It will be set to BusyTSS afterward.
	// To reset the TSS, you will need to reset the Segment Type to
	// AvailableTSS.
	ErrorVal install() {
		PhysicalAddress tssPage = PageAllocator.allocPage();

		TaskStateSegment* tss = cast(TaskStateSegment*)tssPage;
		tss = cast(TaskStateSegment*)Paging.mapRegion(tssPage, VirtualMemory.pagesize);
		*tss = TaskStateSegment.init;
		segments[Cpu.identifier] = tss;
		GDT.tables[Cpu.identifier].setSystemSegment((tssBase >> 3), 0x67, (cast(ulong)tss), SystemSegmentType.AvailableTSS, 0, true, false, false);
		asm {
			ltr tssBase;
		}
		return ErrorVal.Success;
	}

	// This structure defines the TSS used by the architecture
	align(1) struct TaskStateSegment {
	private:
		uint reserved0;		// Reserved Space

		void* rsp0;			// The stack to use for Ring 0 Interrupts
		void* rsp1;			// For Ring 1 Interrupts
		void* rsp2;			// For Ring 2 Interrupts

		ulong reserved1;	// Reserved Space

		void*[7] ist;		// IST space

		ulong reserved2;	// Reserved Space
		ushort reserved3;	// Reserved Space

		ushort ioMap;		// IO Map Base Address (offset until IOPL Map)

	public:
		// This function will set the stack for interrupts that call into
		// ring 0 (kernel mode)
		void RSP0(void* stackPointer) {
			rsp0 = stackPointer;
		}

		void* RSP0() {
			return rsp0;
		}

		void IST(uint index, void* ptr) {
			ist[index] = ptr;
		}

		void* IST(uint index) {
			return ist[index];
		}
	}

	TaskStateSegment* table() {
		return segments[Cpu.identifier];
	}

private:

	ushort tssBase = 0x30;

	TaskStateSegment*[256] segments;
}
