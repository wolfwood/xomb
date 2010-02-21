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
	uint read32(ushort bus, ushort slot, ushort func, ushort offset) {
		return 0;
	}

	// Description: Will read a ushort from PCI.
	ushort read16(ushort bus, ushort slot, ushort func, ushort offset) {
		return 0;
	}

	// Description: Will read a ubyte from PCI.
	ubyte read8(ushort bus, ushort slot, ushort func, ushort offset) {
		return 0;
	}

	// Description: Will write to PCI.
	void write() {
	}
}
