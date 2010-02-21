/*
 * pci.d
 *
 * This module implements the architecture specific parts of the PCI spec.
 *
 */

module architecture.pci;

class PCIImplementation {
static:

	// Description: Will read a uint from PCI.
	uint read32(uint address, ubyte offset) {
		return 0;
	}

	// Description: Will read a ushort from PCI.
	ushort read16(uint address, ubyte offset) {
		return 0;
	}

	// Description: Will read a ubyte from PCI.
	ubyte read8(uint address, ubyte offset) {
		return 0;
	}

	// Description: Will write to PCI.
	void write8(uint address, ubyte offset, ubyte value) {
	}

	// Description: Will write to PCI.
	void write16(uint address, ubyte offset, ushort value) {
	}

	// Description: Will write to PCI.
	void write32(uint address, ubyte offset, uint value) {
	}
}
