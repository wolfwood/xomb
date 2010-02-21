/*
 * pci.d
 *
 * This module implements the PCI specification.
 *
 */

module kernel.dev.pci;

import architecture.pci;

class PCI : PCIImplementation {
	// Description: This function will verify a bus and slot exist.
	bool verify(ushort bus, ushort slot) {
		ushort vendor = read16(bus, slot, 0, 0);

		if (vendor == 0xffff) {
			// no vendor can be all ones
			// PCI will return all ones on an invalid request
			// therefore, this bus and slot are invalid
			return false;
		}

		return true;
	}
}
