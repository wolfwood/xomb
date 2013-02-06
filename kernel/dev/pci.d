/*
 * pci.d
 *
 * This module implements the PCI specification.
 *
 */

module kernel.dev.pci;

import architecture.pci;
import architecture.cpu;

import kernel.core.error;
import kernel.core.kprintf;

import kernel.system.info;
import kernel.system.definitions;


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

	uint baseAddress(uint i) {
		return read32(PCI.Offset.BaseAddress0 + (4 * i));
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

	struct IOEntry {
		bool isIO;
		ubyte* address;
		bool prefetchable;
	}

	IOEntry[6] _entries;

private:

	ubyte read8(ubyte offset) {
		return PCI.read8(_address | offset);
	}

	ushort read16(ubyte offset) {
		return PCI.read16(_address | offset);
	}

	uint read32(ubyte offset) {
		return PCI.read32(_address | offset);
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

	uint baseAddress(uint i) {
		return read32(PCI.Offset.BaseAddress0 + (4 * i));
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

	ulong prefetchableMemoryLimit() {
		return cast(ulong)read16(PCI.BridgeOffset.PrefetchableMemoryLimit)
			| (cast(ulong)read32(PCI.BridgeOffset.PrefetchableLimitUpper32) << 32);
	}

	ulong prefetchableMemoryBase() {
		return cast(ulong)read16(PCI.BridgeOffset.PrefetchableMemoryBase)
			| (cast(ulong)read32(PCI.BridgeOffset.PrefetchableBaseUpper32) << 32);
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
		return PCI.read8(_address | offset);
	}

	ushort read16(ubyte offset) {
		return PCI.read16(_address | offset);
	}

	uint read32(ubyte offset) {
		return PCI.read32(_address | offset);
	}
}

class PCI : PCIConfiguration {
static:

	enum Offset : ubyte {
		VendorID,
		DeviceID = 0x2,
		Command = 0x4,
		Status = 0x6,
		RevisionID = 0x8,
		ProgIF = 0x9,
		Subclass = 0xa,
		ClassCode = 0xb,
		CacheLineSize = 0xc,
		LatencyTimer = 0xd,
		HeaderType = 0xe,
		BIST = 0xf,
		BaseAddress0 = 0x10,
		BaseAddress1 = 0x14,
		BaseAddress2 = 0x18,
		BaseAddress3 = 0x1c,
		BaseAddress4 = 0x20,
		BaseAddress5 = 0x24,
		CardbusCISPtr = 0x28,
		SubsystemVendorID = 0x2c,
		SubsystemID = 0x2e,
		ExpansionRomBaseAddress = 0x30,
		CapabilitiesPointer = 0x34,
		InterruptLine = 0x3c,
		InterruptPin = 0x3d,
		MinGrant = 0x3e,
		MaxLatency = 0x3f
	}

	enum BridgeOffset : ubyte {
		VendorID,
		DeviceID = 0x2,
		Command = 0x4,
		Status = 0x6,
		RevisionID = 0x8,
		ProgIF = 0x9,
		Subclass = 0xa,
		ClassCode = 0xb,
		CacheLineSize = 0xc,
		LatencyTimer = 0xd,
		HeaderType = 0xe,
		BIST = 0xf,
		BaseAddress0 = 0x10,
		BaseAddress1 = 0x14,
		PrimaryBusNumber = 0x18,
		SecondaryBusNumber = 0x19,
		SubordinateBusNumber = 0x1a,
		SecondaryLatencyTimer = 0x1b,
		IOBase = 0x1c,
		IOLimit = 0x1d,
		SecondaryStatus = 0x1e,
		MemoryBase = 0x20,
		MemoryLimit = 0x22,
		PrefetchableMemoryBase = 0x24,
		PrefetchableMemoryLimit = 0x26,
		PrefetchableBaseUpper32 = 0x28,
		PrefetchableLimitUpper32 = 0x2c,
		IOBaseUpper16 = 0x30,
		IOLimitUpper16 = 0x32,
		CapabilitiesPointer = 0x34,
		ExpansionRomBaseAddress = 0x38,
		InterruptLine = 0x3c,
		InterruptPin = 0x3d,
		BridgeControl = 0x3e
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
//		kprintfln!("Scanning PCI Bus {}")(bus);

		void printDevice() {
//			kprintfln!("PCI Address: {x} Device ID: {x} Vendor ID: {x}")
				(current.address, current.deviceID, current.vendorID);
		}

		void vga_w(ubyte* base, ushort reg, ubyte val) {
//			kprintfln!("vga write port {x} value {x}")(reg, val);
			Cpu.ioOut!(ubyte)(reg, val);
//			*(base + reg) = val;
		}

		void loadDevice(uint deviceIndex) {
			Device* dev = &System.deviceInfo[deviceIndex];

			if (dev.bus.pci.deviceID == 0x1111 && dev.bus.pci.vendorID == 0x1234) {
				// Bochs Video
				ubyte* addr = dev.bus.pci._entries[0].address;
				addr --;
//				kprintfln!("Video card found: Bochs Video")();
			}
		}

		void foundDevice() {
			printDevice();

			// Find out the ioentries for this device
			for (int i; i < 6; i++) {
				uint baseAddress = current.baseAddress(i);
				if ((baseAddress & 0x1) == 0x1) {
					// IO Space
					current._entries[i].isIO = true;
					current._entries[i].prefetchable = false;
					current._entries[i].address = cast(ubyte*)(baseAddress & (~0x03));
				}
				else {
					// Memory Space
					current._entries[i].isIO = false;
					current._entries[i].prefetchable = ((baseAddress >> 3) & 0x1) == 0x1;
					current._entries[i].address = cast(ubyte*)(baseAddress & (~0x0f));
				}
//				kprintfln!("{}: isIO: {} address: {}")(i,current._entries[i].isIO, current._entries[i].address);
			}

			System.deviceInfo[System.numDevices].type = Device.BusType.PCI;
			System.deviceInfo[System.numDevices].bus.pci = current;
//			kprintfln!("Assigned Device ID {} isIO: {} address: {}")(System.numDevices, current._entries[0].isIO, current._entries[0].address);
			System.numDevices++;

			loadDevice(System.numDevices-1);
		}

		void checkForBridge() {
			if ((current.headerType & 0x7f) == 0x1) {
				// Is a PCI-PCI Bridge
				PCIBridge curBridge;
				curBridge._address = current._address;
				scanBus(curBridge.secondaryBusNumber);
			}
			else {
				// Found a device
				foundDevice();
			}
		}

		for (uint device = 0; device < 32; device++) {
			// Is this device's header valid?
			current._address = address(bus, device, 0);
			if (current.vendorID != 0xffff) {
				// Check the header
//				kprintfln!("device: {}, function: {}")(device, 0);
				checkForBridge();

				bool hasFunctions = true;

				/*
				ubyte busHeaderType = current.headerType;
				hasFunction = (busHeaderType & 0x80) == 0x80;
				*/

				if (hasFunctions) {
					// the header type field will tell us if multiple functions exist
					// this is true when bit 7 is set

					// Yet again, the functions are limited by the address field layout
//					kprintfln!("Checking functions")();
					for (uint func = 1; func < 8; func++) {
						current._address = address(bus, device, func);
						if (current.vendorID != 0xffff) {
	//						kprintfln!("device: {}, function: {}")(device, func);
							checkForBridge();
						}
					}
				}
			}
		}
	}

	// Description: Will compute the address for a particular device.
	uint address(ushort bus, ushort device, ushort func, ushort offset) {
		return (cast(uint)bus << 16) | (cast(uint)device << 11)
				| (cast(uint)func << 8) | (cast(uint)offset & 0xfc)
				| (cast(uint)0x80000000);
	}

	// Description: Will compute the address for a particular device without the offset.
	uint address(ushort bus, ushort device, ushort func) {
		return (cast(uint)bus << 16) | (cast(uint)device << 11)
				| (cast(uint)func << 8)
				| (cast(uint)0x80000000);
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
