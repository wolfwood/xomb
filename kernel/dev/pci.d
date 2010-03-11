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

import kernel.mem.gib;
import kernel.mem.giballocator;
import kernel.filesystem.ramfs;

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
		kprintfln!("Scanning PCI Bus {}")(bus);

		void printDevice() {
			kprintfln!("PCI Address: {x} Device ID: {x} Vendor ID: {x}")
				(current.address, current.deviceID, current.vendorID);
		}

		void vga_w(ubyte* base, ushort reg, ubyte val) {
			kprintfln!("vga write port {x} value {x}")(reg, val);
			Cpu.ioOut!(ubyte)(reg, val);
//			*(base + reg) = val;
		}

		void loadDevice(uint deviceIndex) {
			Device* dev = &System.deviceInfo[deviceIndex];

			if (dev.bus.pci.deviceID == 0x1111 && dev.bus.pci.vendorID == 0x1234) {
				// Bochs Video
				ubyte* addr = dev.bus.pci._entries[0].address;
				addr --;
				kprintfln!("Video card found: Cirrus Logic")();
				// Do foo (for practice :))

				Gib device = RamFS.create("/devices/vga", Access.Kernel | Access.Read | Access.Write);

				device.map(addr, 1024*1024*5);
				addr = device.ptr;

				static const ushort VGA_GFX_D = 0x3cf;
				static const ushort VGA_GFX_I = 0x3ce;

				static const ushort VGA_SEQ_I = 0x3c4;
				static const ushort VGA_SEQ_D = 0x3c5;

				static const ushort VGA_ATT_IW = 0x3c0;
				static const ushort VGA_ATT_W = 0x3c0;

				static const ushort VGA_MIS_W = 0x3c2;

				static const ushort VGA_PEL_MSK = 0x3c6;

				static const ushort VGA_GFX_MODE = 0x05;

				static const ushort CL_GRB = 0xb;
				static const ushort CL_GRC = 0xc;
				static const ushort CL_GRD = 0xd;
				static const ushort CL_GRE = 0xe;
				static const ushort CL_GR2F = 0x2f;
				static const ushort CL_GR31 = 0x31;
				static const ushort CL_GR33 = 0x33;

				static const ushort CL_AR33 = 0x33;

				static const ushort CL_CRT1A = 0x1a;
				static const ushort CL_CRT1B = 0x1b;
				static const ushort CL_CRT51 = 0x51;

				static const ushort CL_SEQR7 = 0x7;

				static const ushort VGA_SEQ_PLANE_WRITE = 0x02;
				static const ushort VGA_SEQ_CHARACTER_MAP = 0x03;
				static const ushort VGA_SEQ_MEMORY_MODE = 0x04;

				static const ushort VGA_GFX_MISC = 0x06;
				static const ushort VGA_GFX_COMPARE_MASK = 0x07;
				static const ushort VGA_GFX_BIT_MASK = 0x08;

				static const ushort VGA_ATC_MODE = 0x10;
				static const ushort VGA_ATC_OVERSCAN = 0x11;
				static const ushort VGA_ATC_PLANE_ENABLE = 0x12;
				static const ushort VGA_ATC_COLOR_PAGE = 0x14;

				static const ushort VGA_CRT_IC = 0x3d4;
				static const ushort VGA_CRT_DC = 0x3d5;
				static const ushort VGA_CRTC_H_TOTAL = 0x00;
				static const ushort VGA_CRTC_H_DISP = 0x01;
				static const ushort VGA_CRTC_H_BLANK_START = 0x02;
				static const ushort VGA_CRTC_H_BLANK_END = 0x03;
				static const ushort VGA_CRTC_H_SYNC_START = 0x04;
				static const ushort VGA_CRTC_H_SYNC_END = 0x05;
				static const ushort VGA_CRTC_V_TOTAL = 0x06;
				static const ushort VGA_CRTC_OVERFLOW = 0x07;
				static const ushort VGA_CRTC_PRESET_ROW = 0x08;
				static const ushort VGA_CRTC_MAX_SCAN = 0x09;
				static const ushort VGA_CRTC_CURSOR_START = 0x0a;
				static const ushort VGA_CRTC_CURSOR_END = 0x0b;
				static const ushort VGA_CRTC_START_HI = 0x0c;
				static const ushort VGA_CRTC_START_LO = 0x0d;
				static const ushort VGA_CRTC_CURSOR_HI = 0x0e;
				static const ushort VGA_CRTC_CURSOR_LO = 0x0f;
				static const ushort VGA_CRTC_V_SYNC_START = 0x10;
				static const ushort VGA_CRTC_V_SYNC_END = 0x11;
				static const ushort VGA_CRTC_V_DISP_END = 0x12;
				static const ushort VGA_CRTC_OFFSET = 0x13;
				static const ushort VGA_CRTC_UNDERLINE = 0x14;
				static const ushort VGA_CRTC_V_BLANK_START = 0x15;
				static const ushort VGA_CRTC_V_BLANK_END = 0x16;
				static const ushort VGA_CRTC_MODE = 0x17;
				static const ushort VGA_CRTC_LINE_COMPARE = 0x18;

				// init
				vga_w(addr, VGA_CRT_IC, CL_CRT51);
				vga_w(addr, VGA_CRT_DC, 0x0);

				vga_w(addr, VGA_GFX_I, CL_GR31);
				vga_w(addr, VGA_GFX_D, 0x0);

				vga_w(addr, VGA_GFX_I, CL_GR2F);
				vga_w(addr, VGA_GFX_D, 0x0);

				vga_w(addr, VGA_GFX_I, CL_GR33);
				vga_w(addr, VGA_GFX_D, 0x0);

				// plane mask
				vga_w(addr, VGA_SEQ_I, VGA_SEQ_PLANE_WRITE);
				vga_w(addr, VGA_SEQ_D, 0xff);

				// character map select
				vga_w(addr, VGA_SEQ_I, VGA_SEQ_CHARACTER_MAP);
				vga_w(addr, VGA_SEQ_D, 0x00);

				vga_w(addr, VGA_SEQ_I, VGA_SEQ_MEMORY_MODE);
				vga_w(addr, VGA_SEQ_D, 0x02);

				// mode
				vga_w(addr, VGA_GFX_I, VGA_GFX_MODE);
				vga_w(addr, VGA_GFX_D, 0x00);

				// misc (memory mapped address, graphics mode = 1)
				vga_w(addr, VGA_GFX_I, VGA_GFX_MISC);
				vga_w(addr, VGA_GFX_D, 0x05);

				// Color (involve all planes)
				vga_w(addr, VGA_GFX_I, VGA_GFX_COMPARE_MASK);
				vga_w(addr, VGA_GFX_D, 0xf);

				// Bit mask (no mask)
				vga_w(addr, VGA_GFX_I, VGA_GFX_BIT_MASK);
				vga_w(addr, VGA_GFX_D, 0xff);

				// Color Key compare
				vga_w(addr, VGA_GFX_I, CL_GRC);
				vga_w(addr, VGA_GFX_D, 0xff);

				// Color compare mask
				vga_w(addr, VGA_GFX_I, CL_GRD);
				vga_w(addr, VGA_GFX_D, 0x0);

				// Misc control
				vga_w(addr, VGA_GFX_I, CL_GRE);
				vga_w(addr, VGA_GFX_D, 0x00);

				// Set graphics mode
				vga_w(addr, VGA_ATT_IW, VGA_ATC_MODE);
				vga_w(addr, VGA_ATT_W, 0x01);

				// Overscan color (black)
				vga_w(addr, VGA_ATT_IW, VGA_ATC_OVERSCAN);
				vga_w(addr, VGA_ATT_W, 0x00);

				// Color Plane enable (all planes)
				vga_w(addr, VGA_ATT_IW, VGA_ATC_PLANE_ENABLE);
				vga_w(addr, VGA_ATT_W, 0x0f);

				// Color select
				vga_w(addr, VGA_ATT_IW, VGA_ATC_COLOR_PAGE);
				vga_w(addr, VGA_ATT_W, 0x00);

				// given
				uint xres = 1280; // resolution
				uint yres = 1024;

				uint lm = 8; // left margin
				uint rm = 8; // right margin
				uint bm = 8; // bottom margin
				uint tm = 8; // top margin

				uint hsynclen = 8; // hsynclen
				uint vsynclen = 8; // vsynclen

				// computed
				uint htotal = ((lm + xres + rm + hsynclen) / 8) - 5;
				uint hdispend = (xres / 8) - 1;
				uint hsyncstart = ((xres + rm) / 8) + 1;
				uint hsyncend = ((xres + rm + hsynclen) / 8) + 1;

				uint div = 1;
				if (yres >= 1024) {
					div = 2;
				}

				uint vtotal = ((yres + tm + bm + vsynclen) / div) - 2;
				uint vdispend = yres - 1;
				uint vsyncstart = ((yres + bm) / div) - 1;
				uint vsyncend = ((yres + bm + vsynclen) / div) - 1;

				vga_w(addr, VGA_CRT_IC, VGA_CRTC_V_SYNC_END);
				vga_w(addr, VGA_CRT_DC, 0x20);

				vga_w(addr, VGA_CRT_IC, VGA_CRTC_H_TOTAL);
				vga_w(addr, VGA_CRT_DC, cast(ubyte)htotal);

				vga_w(addr, VGA_CRT_IC, VGA_CRTC_H_DISP);
				vga_w(addr, VGA_CRT_DC, cast(ubyte)hdispend);

				vga_w(addr, VGA_CRT_IC, VGA_CRTC_H_BLANK_START);
				vga_w(addr, VGA_CRT_DC, cast(ubyte)(xres / 8));

				vga_w(addr, VGA_CRT_IC, VGA_CRTC_H_BLANK_END);
				vga_w(addr, VGA_CRT_DC, cast(ubyte)((htotal + 5) % 32) + 128);

				vga_w(addr, VGA_CRT_IC, VGA_CRTC_H_SYNC_START);
				vga_w(addr, VGA_CRT_DC, cast(ubyte)hsyncstart);

				int tmp = hsyncend % 32;
				if (((htotal + 5) & 32) > 0) {
					tmp |= 128;
				}
				vga_w(addr, VGA_CRT_IC, VGA_CRTC_H_SYNC_END);
				vga_w(addr, VGA_CRT_DC, cast(ubyte)tmp);

				vga_w(addr, VGA_CRT_IC, VGA_CRTC_V_TOTAL);
				vga_w(addr, VGA_CRT_DC, cast(ubyte)vtotal);

				tmp = 16;
				if ((vtotal & 256) > 0) {
					tmp |= 1;
				}
				if ((vdispend & 256) > 0) {
					tmp |= 2;
				}
				if ((vsyncstart & 256) > 0) {
					tmp |= 4;
				}
				if (((vdispend+1) & 256) > 0) {
					tmp |= 8;
				}
				if ((vtotal & 512) > 0) {
					tmp |= 32;
				}
				if ((vdispend & 512) > 0) {
					tmp |= 64;
				}
				if ((vsyncstart & 512) > 0) {
					tmp |= 128;
				}
				vga_w(addr, VGA_CRT_IC, VGA_CRTC_OVERFLOW);
				vga_w(addr, VGA_CRT_DC, cast(ubyte)tmp);

				tmp = 0x40; // line compare bit 8
				if (((vdispend + 1) & 512) > 0) {
					tmp |= 0x20;
				}
				vga_w(addr, VGA_CRT_IC, VGA_CRTC_MAX_SCAN);
				vga_w(addr, VGA_CRT_DC, cast(ubyte)tmp);

				vga_w(addr, VGA_CRT_IC, VGA_CRTC_V_SYNC_START);
				vga_w(addr, VGA_CRT_DC, cast(ubyte)vsyncstart);

				vga_w(addr, VGA_CRT_IC, VGA_CRTC_V_SYNC_END);
				vga_w(addr, VGA_CRT_DC, cast(ubyte)vsyncend);

				vga_w(addr, VGA_CRT_IC, VGA_CRTC_V_DISP_END);
				vga_w(addr, VGA_CRT_DC, cast(ubyte)vdispend);

				vga_w(addr, VGA_CRT_IC, VGA_CRTC_V_BLANK_START);
				vga_w(addr, VGA_CRT_DC, cast(ubyte)(vdispend+1));

				vga_w(addr, VGA_CRT_IC, VGA_CRTC_V_BLANK_END);
				vga_w(addr, VGA_CRT_DC, cast(ubyte)vtotal);

				vga_w(addr, VGA_CRT_IC, VGA_CRTC_LINE_COMPARE);
				vga_w(addr, VGA_CRT_DC, cast(ubyte)0xff);

				tmp = 0;
				if (((htotal+5) & 64) > 0) {
					tmp |= 16;
				}
				if (((htotal+5) & 128) > 0) {
					tmp |= 32;
				}
				if ((vtotal & 256) > 0) {
					tmp |= 64;
				}
				if ((vtotal & 512) > 0) {
					tmp |= 128;
				}

				vga_w(addr, VGA_CRT_IC, CL_CRT1A);
				vga_w(addr, VGA_CRT_DC, cast(ubyte)tmp);

				vga_w(addr, VGA_CRT_IC, VGA_CRTC_MODE);
				if (yres >= 1024) {
					vga_w(addr, VGA_CRT_DC, cast(ubyte)0xc7);
				}
				else {
					vga_w(addr, VGA_CRT_DC, cast(ubyte)0xc3);
				}

				// horiz and vert sync type (low/high)
				// VCLK3

				// enable display memory & CRTC I/O address for
				// color mode
				tmp = 0xf;

				vga_w(addr, VGA_MIS_W, tmp);

				// text cursor on and start line
				vga_w(addr, VGA_CRT_IC, VGA_CRTC_CURSOR_START);
				vga_w(addr, VGA_CRT_DC, 0);

				// text cursor end line
				vga_w(addr, VGA_CRT_IC, VGA_CRTC_CURSOR_END);
				vga_w(addr, VGA_CRT_DC, 31);

				// setting color mode 24 bpp
				// CL_SEQR7 = 0xa5
				vga_w(addr, VGA_SEQ_I, CL_SEQR7);
				vga_w(addr, VGA_SEQ_D, 0xa5);

				// set mode register to 256 color mode
				vga_w(addr, VGA_GFX_I, VGA_GFX_MODE);
				vga_w(addr, VGA_GFX_D, 64);

				// set hidden DAC register to 8-8-8 mode
				vga_w(addr, VGA_PEL_MSK, 0xc5);

				int pitch = 0;

				// bytes per line
				pitch = (xres * 24 >> 3) >> 3;

				tmp = 0x22;
				if ((pitch & 0x100) > 0) {
					tmp |= 0x10;
				}

				// Turn on Video Bit
				vga_w(addr, VGA_ATT_IW, 0x33);
				vga_w(addr, VGA_ATT_IW, 0x00);

				vga_w(addr, VGA_CRT_IC, CL_CRT1B);
				vga_w(addr, VGA_CRT_DC, cast(ubyte)tmp);

				vga_w(addr, VGA_CRT_IC, VGA_CRTC_OFFSET);
				vga_w(addr, VGA_CRT_DC, cast(ubyte)pitch);

				// pixel panning
				vga_w(addr, VGA_ATT_IW, CL_AR33);
				vga_w(addr, VGA_ATT_W, 0);

				uint* ffaddr = cast(uint*)0xa0000;
				Gib g = RamFS.create("/devices/vga1", Access.Kernel|Access.Read|Access.Write);
				g.map(cast(ubyte*)ffaddr, 1024*1024);
				ffaddr = cast(uint*)g.ptr;
				for (uint i; i < 10000; i++) {
					*ffaddr = 0xffffffff;
					ffaddr++;
				}

				uint* faddr = cast(uint*)addr;
				for (uint i; i < 10000; i++) {
					*faddr = 0xffffffff;	
					faddr++;
				}
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
			kprintfln!("Assigned Device ID {} isIO: {} address: {}")(System.numDevices, current._entries[0].isIO, current._entries[0].address);
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
				kprintfln!("device: {}, function: {}")(device, 0);
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
					kprintfln!("Checking functions")();
					for (uint func = 1; func < 8; func++) {
						current._address = address(bus, device, func);
						if (current.vendorID != 0xffff) {
							kprintfln!("device: {}, function: {}")(device, func);
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
