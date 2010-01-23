/* pic.d
 *
 * The architecture code to handle the PIC.
 *
 */

module kernel.arch.x86_64.core.pic;

import architecture.cpu;

struct PIC {
static:
	void disable() {
		// Masks all IRQs
		Cpu.ioOut!(byte, "0xA1")(0xFF);
		Cpu.ioOut!(byte, "0x21")(0xFF);
	}

	void enableAll() {
		// Unmasks all IRQs
		Cpu.ioOut!(byte, "0xA1")(0x00);
		Cpu.ioOut!(byte, "0x21")(0x00);
	}

	void disableIRQ(uint irq) {
		// port 21 : irqs 0 - 7
		// port A1 : irqs 8 - 15

		// Disable by writing a 1 at that bit position

		if (irq > 7) {
			// using port A1
			irq -= 8;
			byte curMask = Cpu.ioIn!(byte, "0xA1")();
			curMask |= cast(byte)(1 << irq);
			Cpu.ioOut!(byte, "0xA1")(curMask);
		}
		else {
			// using port 21
			byte curMask = Cpu.ioIn!(byte, "0x21")();
			curMask |= cast(byte)(1 << irq);
			Cpu.ioOut!(byte, "0x21")(curMask);
		}
	}

	void enableIRQ(uint irq) {
		// port 21 : irqs 0 - 7
		// port A1 : irqs 8 - 15

		// Disable by writing a 1 at that bit position

		if (irq > 7) {
			// using port A1
			irq -= 8;
			byte curMask = Cpu.ioIn!(byte, "0xA1")();
			curMask &= cast(byte)(~(1 << irq));
			Cpu.ioOut!(byte, "0xA1")(curMask);
		}
		else {
			// using port 21
			byte curMask = Cpu.ioIn!(byte, "0x21")();
			curMask &= cast(byte)(~(1 << irq));
			Cpu.ioOut!(byte, "0x21")(curMask);
		}
	}

	void EOI(uint irq) {
		if (irq > 7) {
			// Pic Slave
			Cpu.ioOut!(ubyte, "0x20")(0x20);
			Cpu.ioOut!(ubyte, "0xA0")(0x20);
		}
		else {
			// Pic Master
			Cpu.ioOut!(ubyte, "0x20")(0x20);
		}
	}
}
