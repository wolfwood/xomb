/*
 * pci.d
 *
 * This module implements the PCI specification.
 *
 */

module kernel.dev.pci;

import architecture.pci;

import kernel.core.error;
import kernel.core.kprintf;

	// PCI Configuration
	// ------------------------
	// Address Field:
	//  /-------------------- Enable Bit	[31]
	//  | /------------------ Reserved		[30-24]
	//  | |    /------------- Bus #			[23-16]
	//  | |    |    /-------- Device # 		[15-11]
	//  | |    |    |    /--- Function #	[10-08]
	//  | |    |    |    | /- Register #	[07-02]
	//  | |    |    |    | |
	// [.|....|....|....|.|..|00]
	//
	// This field selects a device and can be set
	// via port 0xcf8 and used to direct where
	// configuration headers can be read.
	// ------------------------

struct PCIDevice {
	uint address() {
		return _address;
	}

	ushort deviceID() {
		return read16(PCI.Offset.DeviceID);
	}

	ushort vendorID() {
		return read16(PCI.Offset.VendorID);
	}

	ushort status() {
		return read16(PCI.Offset.Status);
	}

	ushort command() {
		return read16(PCI.Offset.Command);
	}

	ubyte classCode() {
		return read8(PCI.Offset.ClassCode);
	}

	ubyte subclass() {
		return read8(PCI.Offset.Subclass);
	}

	ubyte progIF() {
		return read8(PCI.Offset.ProgIF);
	}

	ubyte revisionID() {
		return read8(PCI.Offset.RevisionID);
	}

	ubyte BIST() {
		return read8(PCI.Offset.BIST);
	}

	ubyte headerType() {
		return read8(PCI.Offset.HeaderType);
	}

	ubyte latencyTimer() {
		return read8(PCI.Offset.LatencyTimer);
	}

	ubyte cacheLineSize() {
		return read8(PCI.Offset.CacheLineSize);
	}

	uint baseAddress0() {
		return read32(PCI.Offset.BaseAddress0);
	}

	uint baseAddress1() {
		return read32(PCI.Offset.BaseAddress1);
	}

	uint baseAddress2() {
		return read32(PCI.Offset.BaseAddress2);
	}

	uint baseAddress3() {
		return read32(PCI.Offset.BaseAddress3);
	}

	uint baseAddress4() {
		return read32(PCI.Offset.BaseAddress4);
	}

	uint baseAddress5() {
		return read32(PCI.Offset.BaseAddress5);
	}

	ushort subsystemID() {
		return read16(PCI.Offset.SubsystemID);
	}

	ushort subsystemVendorID() {
		return read16(PCI.Offset.SubsystemVendorID);
	}

	uint expansionRomBaseAddress() {
		return read32(PCI.Offset.ExpansionRomBaseAddress);
	}

	ubyte capabilitiesPointer() {
		return read8(PCI.Offset.CapabilitiesPointer);
	}

	ubyte maxLatency() {
		return read8(PCI.Offset.MaxLatency);
	}

	ubyte minGrant() {
		return read8(PCI.Offset.MinGrant);
	}

	ubyte interruptPin() {
		return read8(PCI.Offset.InterruptPin);
	}

	ubyte interruptLine() {
		return read8(PCI.Offset.InterruptLine);
	}

package:
	uint _address;

private:

	ubyte read8(ubyte offset) {
		return PCI.read8(_address | PCI.Offset.HeaderType);
	}

	ushort read16(ubyte offset) {
		return PCI.read16(_address | PCI.Offset.HeaderType);
	}

	uint read32(ubyte offset) {
		return PCI.read32(_address | PCI.Offset.HeaderType);
	}
}

struct PCIBridge {
	uint address() {
		return _address;
	}

	ushort deviceID() {
		return read16(PCI.Offset.DeviceID);
	}

	ushort vendorID() {
		return read16(PCI.Offset.VendorID);
	}

	ushort status() {
		return read16(PCI.Offset.Status);
	}

	ushort command() {
		return read16(PCI.Offset.Command);
	}

	ubyte classCode() {
		return read8(PCI.Offset.ClassCode);
	}

	ubyte subclass() {
		return read8(PCI.Offset.Subclass);
	}

	ubyte progIF() {
		return read8(PCI.Offset.ProgIF);
	}

	ubyte revisionID() {
		return read8(PCI.Offset.RevisionID);
	}

	ubyte BIST() {
		return read8(PCI.Offset.BIST);
	}

	ubyte headerType() {
		return read8(PCI.Offset.HeaderType);
	}

	ubyte latencyTimer() {
		return read8(PCI.Offset.LatencyTimer);
	}

	ubyte cacheLineSize() {
		return read8(PCI.Offset.CacheLineSize);
	}

	uint baseAddress0() {
		return read32(PCI.Offset.BaseAddress0);
	}

	uint baseAddress1() {
		return read32(PCI.Offset.BaseAddress1);
	}

	ubyte secondaryLatencyTimer() {
		return read8(PCI.BridgeOffset.SecondaryLatencyTimer);
	}

	ubyte subordinateBusNumber() {
		return read8(PCI.BridgeOffset.SubordinateBusNumber);
	}

	ubyte secondaryBusNumber() {
		return read8(PCI.BridgeOffset.SecondaryBusNumber);
	}

	ubyte primaryBusNumber() {
		return read8(PCI.BridgeOffset.PrimaryBusNumber);
	}

	ushort secondaryStatus() {
		return read16(PCI.BridgeOffset.SecondaryStatus);
	}

	ushort IOLimit() {
		return cast(ushort)(read8(PCI.BridgeOffset.IOLimit)
			| (read16(PCI.BridgeOffset.IOLimitUpper16) << 16));
	}

	ushort IOBase() {
		return cast(ushort)(read8(PCI.BridgeOffset.IOBase)
			| (read16(PCI.BridgeOffset.IOBaseUpper16) << 16));
	}

	ushort memoryLimit() {
		return read16(PCI.BridgeOffset.MemoryLimit);
	}

	ushort memoryBase() {
		return read16(PCI.BridgeOffset.MemoryBase);
	}

	uint prefetchableMemoryLimit() {
		return cast(uint)read16(PCI.BridgeOffset.PrefetchableMemoryLimit)
			| (read32(PCI.BridgeOffset.PrefetchableLimitUpper32) << 32);
	}

	uint prefetchableMemoryBase() {
		return cast(uint)read16(PCI.BridgeOffset.PrefetchableMemoryBase)
			| (read32(PCI.BridgeOffset.PrefetchableBaseUpper32) << 32);
	}

	uint expansionRomBaseAddress() {
		return read32(PCI.Offset.ExpansionRomBaseAddress);
	}

	ubyte capabilitiesPointer() {
		return read8(PCI.Offset.CapabilitiesPointer);
	}

	ushort bridgeControl() {
		return read16(PCI.BridgeOffset.BridgeControl);
	}

	ubyte interruptPin() {
		return read8(PCI.BridgeOffset.InterruptPin);
	}

	ubyte interruptLine() {
		return read8(PCI.BridgeOffset.InterruptLine);
	}

package:

	uint _address;

private:

	ubyte read8(ubyte offset) {
		return PCI.read8(_address | PCI.Offset.HeaderType);
	}

	ushort read16(ubyte offset) {
		return PCI.read16(_address | PCI.Offset.HeaderType);
	}

	uint read32(ubyte offset) {
		return PCI.read32(_address | PCI.Offset.HeaderType);
	}
}

class PCI : PCIConfiguration {
static:

	enum Offset : ubyte {
		DeviceID,
		VendorID = 0x2,
		Status = 0x4,
		Command = 0x6,
		ClassCode = 0x8,
		Subclass = 0x9,
		ProgIF = 0xa,
		RevisionID = 0xb,
		BIST = 0xc,
		HeaderType = 0xd,
		LatencyTimer = 0xe,
		CacheLineSize = 0xf,
		BaseAddress0 = 0x10,
		BaseAddress1 = 0x14,
		BaseAddress2 = 0x18,
		BaseAddress3 = 0x1c,
		BaseAddress4 = 0x20,
		BaseAddress5 = 0x24,
		CardbusCISPtr = 0x28,
		SubsystemID = 0x2c,
		SubsystemVendorID = 0x2e,
		ExpansionRomBaseAddress = 0x30,
		CapabilitiesPointer = 0x37,
		MaxLatency = 0x3c,
		MinGrant = 0x3d,
		InterruptPin = 0x3e,
		InterruptLine = 0x3f
	}

	enum BridgeOffset : ubyte {
		DeviceID,
		VendorID = 0x2,
		Status = 0x4,
		Command = 0x6,
		ClassCode = 0x8,
		Subclass = 0x9,
		ProgIF = 0xa,
		RevisionID = 0xb,
		BIST = 0xc,
		HeaderType = 0xd,
		LatencyTimer = 0xe,
		CacheLineSize = 0xf,
		BaseAddress0 = 0x10,
		BaseAddress1 = 0x14,
		SecondaryLatencyTimer = 0x18,
		SubordinateBusNumber = 0x19,
		SecondaryBusNumber = 0x1a,
		PrimaryBusNumber = 0x1b,
		SecondaryStatus = 0x1c,
		IOLimit = 0x1e,
		IOBase = 0x1f,
		MemoryLimit = 0x20,
		MemoryBase = 0x22,
		PrefetchableMemoryLimit = 0x24,
		PrefetchableMemoryBase = 0x26,
		PrefetchableBaseUpper32 = 0x28,
		PrefetchableLimitUpper32 = 0x2c,
		IOLimitUpper16 = 0x30,
		IOBaseUpper16 = 0x32,
		CapabilitiesPointer = 0x37,
		ExpansionRomBaseAddress = 0x38,
		BridgeControl = 0x3c,
		InterruptPin = 0x3e,
		InterruptLine = 0x3f
	}

	// Description: Will configure and scan the PCI busses.
	ErrorVal initialize() {
		// scan the busses
		scan();

		// done
		return ErrorVal.Success;
	}

	// Description: Will scan for all devices
	void scan() {
		// Scan Bus 0.
		scanBus(0);
	}

	// Description: Will scan a particular bus
	void scanBus(ushort bus) {
		// There are a maximum of 32 slots due to the address field layout
		PCIDevice current;
		kprintfln!("Scanning PCI Bus {}")(bus);

		void printDevice() {
			kprintfln!("PCI Device ID: {} Vendor ID: {}")(current.deviceID, current.vendorID);
		}

		void checkForBridge() {
			if ((current.headerType & 0x7f) == 0x1) {
				// Is a PCI-PCI Bridge
				PCIBridge curBridge;
				curBridge._address = current._address;
				scanBus(curBridge.secondaryBusNumber);
			}
			else {
				printDevice();
			}
		}

		for (uint device = 0; device < 32; device++) {
			// Is this device's header valid?
			current._address = address(bus, device, 0);
			if (current.vendorID != 0xffff) {
				// Check the header
				checkForBridge();

				if ((current.headerType & 0x80) == 0x80) {
					// the header type field will tell us if multiple functions exist
					// this is true when bit 7 is set

					// Yet again, the functions are limited by the address field layout
					for (uint func = 1; func < 8; func++) {
						current._address = address(bus, device, func);
						if (current.vendorID == 0xffff) {
							break;
						}
						checkForBridge();
					}
				}
			}
		}
	}

	// Description: Will compute the address for a particular device.
	uint address(ushort bus, ushort device, ushort func, ushort offset) {
		return (cast(uint)bus << 16) | (cast(uint)device << 11)
				| (cast(uint)func << 8) | (cast(uint)offset & 0xfc)
				| (cast(uint)0x80000000); // the last value is to set enable bit
	}

	// Description: Will compute the address for a particular device without the offset.
	uint address(ushort bus, ushort device, ushort func) {
		return (cast(uint)bus << 16) | (cast(uint)device << 11)
				| (cast(uint)func << 8)
				| (cast(uint)0x80000000); // the last value is to set enable bit
	}

	ubyte headerType(uint address) {
		return read8(address | Offset.HeaderType);
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
