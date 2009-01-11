module xombemu.x86.interrupt;

import xombemu.x86.memory;
import xombemu.x86.registers;

import std.stdio;

struct Interrupt
{
static:

	void getIVT(uint vector, out ushort cs, out ushort off)
	{
		ulong addr = idtr.i64 + (4*vector);
		uint entry = Memory.read32(addr);
		cs = entry >> 16;
		off = entry & 0xFFFF;

		//writef("Addr: ", addr, " CS: ", cast(long)cs, " OFF: ", cast(long)off, "\n");
	}

	ulong getIDT(uint vector)
	{
		return 0;
	}

	void fire(uint vector)
	{
		// push interrupt stack information

		// get new rip
		ushort newcs, newrip;

		getIVT(vector,newcs,newrip);

		// set new CS and RIP
		cs.i64 = newcs;
		rip.i64 = newrip;
	}
}
