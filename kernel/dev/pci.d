/*
 * pci.d
 *
 * This module implements the PCI specification.
 *
 */

module kernel.dev.pci;

import architecture.pci;

class PCI : PCIImplementation {
	uint address(ushort bus, ushort slot, ushort func, ushort offset) {
		return (cast(uint)bus << 16) | (cast(uint)slot << 11)
				| (cast(uint)func << 8) | (cast(uint)offset & 0xfc)
				| (cast(uint)0x80000000);
	}

	// Description: This function will verify a bus and slot exist.
	bool verify(ushort bus, ushort slot) {
		ushort vendor = read16(address(bus, slot, 0, 0));

		if (vendor == 0xffff) {
			// no vendor can be all ones
			// PCI will return all ones on an invalid request
			// therefore, this bus and slot are invalid
			return false;
		}

		return true;
	}

	// Description: Will read a uint from PCI.
	uint read32(uint address) {
		return read!(uint)(address);
	}

	// Description: Will read a ushort from PCI.
	ushort read16(uint address) {
		return read!(ushort)(address);
	}

	// Description: Will read a ubyte from PCI.
	ubyte read8(uint address) {
		return read!(ubyte)(address);
	}

	// Description: Will write a uint to PCI.
	void write32(uint address, uint value) {
		write(address, value);
	}

	// Description: Will write a ushort to PCI.
	void write16(uint address, ushort value) {
		write(address, value);
	}

	// Description: Will write a ubyte to PCI.
	void write8(uint address, ubyte value) {
		write(address, value);
	}

}
