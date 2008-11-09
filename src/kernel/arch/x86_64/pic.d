module kernel.arch.x86_64.pic;

import kernel.arch.x86_64.init;

struct PIC
{

static:

	void disable()
	{	
		// Mask all irqs
		Cpu.ioOut!(byte, "A1h")(0xFF);
		Cpu.ioOut!(byte, "21h")(0xFF);
	}

	void enableAll()
	{
		// Unmask all irqs
		Cpu.ioOut!(byte, "A1h")(0x0);
		Cpu.ioOut!(byte, "21h")(0x0);
	}

	void disableIRQ(uint irq)
	{
		// port 21 : 0 - 7
		// port A1 : 8 - 15

		// disable by writing a 1 at the bit position of the IRQ

		if (irq > 7)
		{
			irq -= 8;
			byte curMask = Cpu.ioIn!(byte, "A1h")();
			curMask |= cast(byte)(1 << irq);
			Cpu.ioOut!(byte, "A1h")(curMask);
		}
		else
		{
			byte curMask = Cpu.ioIn!(byte, "21h")();
			curMask |= cast(byte)(1 << irq);
			Cpu.ioOut!(byte, "21h")(curMask);
		}
	}

	void enableIRQ(uint irq)
	{
		// port 21 : 0 - 7
		// port A1 : 8 - 15

		// disable by writing a 1 at the bit position of the IRQ

		if (irq > 7)
		{
			irq -= 8;
			byte curMask = Cpu.ioIn!(byte, "A1h")();
			curMask &= cast(byte)(~(1 << irq));
			Cpu.ioOut!(byte, "A1h")(curMask);
		}
		else
		{
			byte curMask = Cpu.ioIn!(byte, "21h")();
			curMask &= cast(byte)(~(1 << irq));
			Cpu.ioOut!(byte, "21h")(curMask);
		}
	}

}
