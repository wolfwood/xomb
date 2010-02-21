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
	synchronized
	uint read32(uint address) {
		_setAddress(address);

		// get offset
		ushort offset = cast(ushort)(address & 0xff);

		// read in data
		return Cpu.ioIn!(uint, "0xcfc")();
	}

	// Description: Will read a ushort from PCI.
	synchronized
	ushort read16(uint address) {
		_setAddress(address);

		// get offset
		ushort offset = cast(ushort)(address & 0xff);

		// read in data
		return Cpu.ioIn!(ushort, "0xcfc")();
	}

	// Description: Will read a ubyte from PCI.
	synchronized
	ubyte read8(uint address) {
		_setAddress(address);

		// get offset
		ushort offset = cast(ushort)(address & 0xff);

		// read in data
		return Cpu.ioIn!(ubyte, "0xcfc")();
	}

	// Description: Will write to PCI.
	synchronized
	void write32(uint address, uint value) {
		_setAddress(address);

		// get offset
		ushort offset = cast(ushort)(address & 0xff);

		// write in data
		Cpu.ioOut!(uint)(0xcfc + offset, value);
	}

	// Description: Will write to PCI.
	synchronized
	void write16(uint address, ushort value) {
		_setAddress(address);

		// get offset
		ushort offset = cast(ushort)(address & 0xff);

		// write in data
		Cpu.ioOut!(ushort)(0xcfc + offset, value);
	}

	// Description: Will write to PCI.
	synchronized
	void write8(uint address, ubyte value) {
		_setAddress(address);

		// get offset
		ushort offset = cast(ushort)(address & 0xff);

		// write in data
		Cpu.ioOut!(ubyte)(0xcfc + offset, value);
	}

private:

	void _setAddress(uint address) {
		// write out address
		Cpu.ioOut!(uint, "0xcf8")(address);
	}
}
