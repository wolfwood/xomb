/*
 * pci.d
 *
 * This module implements the architecture specific parts of the PCI spec.
 *
 */

module architecture.pci;

class PCIImplementation {
static:

	// Description: Will read from PCI.
	ushort read(ushort bus, ushort slot, ushort func, ushort offset) {
		return 0;
	}

	// Description: Will write to PCI.
	void write() {
	}
}
