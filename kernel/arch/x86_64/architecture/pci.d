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

	// Description: This function will verify a bus and slot exist.
	bool verify(ushort bus, ushort slot) {
		ushort vendor = read(bus, slot, 0, 0);

		if (vendor == 0xffff) {
			// no vendor can be all ones
			// PCI will return all ones on an invalid request
			// therefore, this bus and slot are invalid
			return false;
		}

		return true;
	}
}
