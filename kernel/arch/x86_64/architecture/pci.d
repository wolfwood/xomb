/*
 * pci.d
 *
 * This module implements the architecture specific parts of the PCI spec.
 *
 */

module architecture.pci;

import architecture.cpu;

class PCIImplementation {
static:

	// Description: Will read a uint from PCI.
	uint read32(uint address) {
		// write out address
		Cpu.ioOut!(uint, "0xcf8")(address);

		// get offset
		ushort offset = cast(ushort)(address & 0xff);

		// read in data
		Cpu.ioIn!(uint, "0xcfc")();
		return 0;
	}

	// Description: Will read a ushort from PCI.
	ushort read16(uint address) {
		return 0;
	}

	// Description: Will read a ubyte from PCI.
	ubyte read8(uint address) {
		return 0;
	}

	// Description: Will write to PCI.
	void write8(uint address, ubyte value) {
	}

	// Description: Will write to PCI.
	void write16(uint address, ushort value) {
	}

	// Description: Will write to PCI.
	void write32(uint address, uint value) {
	}

private:
}
