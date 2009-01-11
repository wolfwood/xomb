module xombemu.x86.memory;

import std.stdio;

import xombemu.x86.registers;
import xombemu.x86.fetch;

struct Memory
{
static:

	ubyte* ram = null; //&rambase[0];
	ulong ramlen = 0x100000;

	void load()
	{
	}

	void init(ulong loadAddr)
	{
		ram = cast(ubyte*)loadAddr;
	}

	ubyte read8(ulong addr)
	{
		if (addr >= ramlen) {
			// exception
			return 0;
		}

		return *(cast(ubyte*)&ram[addr]);
	}

	ushort read16(ulong addr)
	{
		if (addr + 1 >= ramlen) {
			// exception
			return 0;
		}

		return *(cast(ushort*)&ram[addr]);
		/*ubyte* imm64 = cast(ubyte*)&val;

		// switch immediate	if necessary
		imm64[0] ^= imm64[1];
		imm64[1] ^= imm64[0];
		imm64[0] ^= imm64[1];

		return val;*/
	}

	uint read32(ulong addr)
	{
		if (addr + 3 >= ramlen) {
			// exception
			return 0;
		}

		return *(cast(uint*)&ram[addr]);
		/*ubyte* imm64 = cast(ubyte*)&val;

		// switch immediate	if necessary
		imm64[0] ^= imm64[3];
		imm64[3] ^= imm64[0];
		imm64[0] ^= imm64[3];

		imm64[1] ^= imm64[2];
		imm64[2] ^= imm64[1];
		imm64[1] ^= imm64[2];

		return val;*/
	}

	ulong read64(ulong addr)
	{
		if (addr + 7 >= ramlen) {
			// exception
			return 0;
		}

		return *(cast(ulong*)&ram[addr]);/*
		ubyte* imm64 = cast(ubyte*)&val;

		// switch immediate	if necessary
		imm64[0] ^= imm64[7];
		imm64[7] ^= imm64[0];
		imm64[0] ^= imm64[7];

		imm64[1] ^= imm64[6];
		imm64[6] ^= imm64[1];
		imm64[1] ^= imm64[6];

		imm64[2] ^= imm64[5];
		imm64[5] ^= imm64[2];
		imm64[2] ^= imm64[5];

		imm64[3] ^= imm64[4];
		imm64[4] ^= imm64[3];
		imm64[3] ^= imm64[4];

		return val;*/
	}

	void write8(ulong addr, ubyte val)
	{
		if (addr >= ramlen) {
			// exception
			return 0;
		}

		ram[addr] = val;
	}

	void write16(ulong addr, ushort val)
	{
		if (addr + 1 >= ramlen) {
			// exception
			return 0;
		}

		/*ubyte* imm64 = cast(ubyte*)&val;

		// switch immediate	if necessary
		imm64[0] ^= imm64[1];
		imm64[1] ^= imm64[0];
		imm64[0] ^= imm64[1];*/

		*cast(ushort*)&ram[addr] = val;
	}

	void write32(ulong addr, uint val)
	{
		if (addr + 3 >= ramlen) {
			// exception
			return 0;
		}

		/*ubyte* imm64 = cast(ubyte*)&val;

		// switch immediate	if necessary
		imm64[0] ^= imm64[3];
		imm64[3] ^= imm64[0];
		imm64[0] ^= imm64[3];

		imm64[1] ^= imm64[2];
		imm64[2] ^= imm64[1];
		imm64[1] ^= imm64[2];*/

		*cast(uint*)&ram[addr] = val;
	}

	void write64(ulong addr, ulong val)
	{
		if (addr + 7 >= ramlen) {
			// exception
			return 0;
		}

		/*ubyte* imm64 = cast(ubyte*)&val;

		// switch immediate	if necessary
		imm64[0] ^= imm64[7];
		imm64[7] ^= imm64[0];
		imm64[0] ^= imm64[7];

		imm64[1] ^= imm64[6];
		imm64[6] ^= imm64[1];
		imm64[1] ^= imm64[6];

		imm64[2] ^= imm64[5];
		imm64[5] ^= imm64[2];
		imm64[2] ^= imm64[5];

		imm64[3] ^= imm64[4];
		imm64[4] ^= imm64[3];
		imm64[3] ^= imm64[4];*/

		*cast(ulong*)&ram[addr] = val;
	}









	ulong translateRip()
	{
		ulong val = cs.i64;
		val <<= 4;
		val += rip.i64;

		return val;
	}

	ubyte readRip8()
	{
		if (translateRip() >= ramlen)
		{
			// exception
			return 0;
		}

		ubyte val = *(cast(ubyte*)&ram[translateRip()]);

		rip.i64++;

		return val;
	}

	ushort readRip16()
	{
		if (translateRip() + 1 >= ramlen)
		{
			// exception
			return 0;
		}

		ushort val = *(cast(ushort*)&ram[translateRip()]);
		/*ubyte* imm64 = cast(ubyte*)&val;

		// switch immediate	if necessary
		imm64[0] ^= imm64[1];
		imm64[1] ^= imm64[0];
		imm64[0] ^= imm64[1];*/

		rip.i64+=2;

		return val;
	}

	uint readRip32()
	{
		if (translateRip() + 3 >= ramlen)
		{
			// exception
			return 0;
		}

		uint val = *(cast(uint*)&ram[translateRip()]);
		/*ubyte* imm64 = cast(ubyte*)&val;

		// switch immediate	if necessary
		imm64[0] ^= imm64[3];
		imm64[3] ^= imm64[0];
		imm64[0] ^= imm64[3];

		imm64[1] ^= imm64[2];
		imm64[2] ^= imm64[1];
		imm64[1] ^= imm64[2];*/

		rip.i64+=4;

		return val;
	}

	ulong readRip64()
	{
		if (translateRip() + 7 >= ramlen)
		{
			// exception
			return 0;
		}

		ulong val = *(cast(ulong*)&ram[translateRip()]);
		/*ubyte* imm64 = cast(ubyte*)&val;

		// switch immediate	if necessary
		imm64[0] ^= imm64[7];
		imm64[7] ^= imm64[0];
		imm64[0] ^= imm64[7];

		imm64[1] ^= imm64[6];
		imm64[6] ^= imm64[1];
		imm64[1] ^= imm64[6];

		imm64[2] ^= imm64[5];
		imm64[5] ^= imm64[2];
		imm64[2] ^= imm64[5];

		imm64[3] ^= imm64[4];
		imm64[4] ^= imm64[3];
		imm64[3] ^= imm64[4];*/

		rip.i64+=8;

		return val;
	}

	void advanceRip(long amt)
	{
		rip.i64 += amt;
		rip.i64 &= 0xffff;
	}











	ulong translateAddr(ulong addr)
	{
		ulong val = ds.i64;
		val <<= 4;
		val += addr;

		return val;
	}

	ubyte readMem8(ulong addr)
	{
		if (translateAddr(addr) >= ramlen)
		{
			// exception
			return 0;
		}

		ubyte val = *(cast(ubyte*)&ram[translateAddr(addr)]);

		return val;
	}

	ushort readMem16(ulong addr)
	{
		if (translateAddr(addr) + 1 >= ramlen)
		{
			// exception
			return 0;
		}
		//writefln("addr: %x", translateAddr(addr));

		ushort val = *(cast(ushort*)&ram[translateAddr(addr)]);
		/*ubyte* imm64 = cast(ubyte*)&val;

		// switch immediate	if necessary
		imm64[0] ^= imm64[1];
		imm64[1] ^= imm64[0];
		imm64[0] ^= imm64[1];*/

		return val;
	}

	uint readMem32(ulong addr)
	{
		if (translateAddr(addr) + 3 >= ramlen)
		{
			// exception
			return 0;
		}

		uint val = *(cast(uint*)&ram[translateAddr(addr)]);
		/*ubyte* imm64 = cast(ubyte*)&val;

		// switch immediate	if necessary
		imm64[0] ^= imm64[3];
		imm64[3] ^= imm64[0];
		imm64[0] ^= imm64[3];

		imm64[1] ^= imm64[2];
		imm64[2] ^= imm64[1];
		imm64[1] ^= imm64[2];*/

		return val;
	}

	ulong readMem64(ulong addr)
	{
		if (translateAddr(addr) + 7 >= ramlen)
		{
			// exception
			return 0;
		}

		ulong val = *(cast(ulong*)&ram[translateAddr(addr)]);
		/*ubyte* imm64 = cast(ubyte*)&val;

		// switch immediate	if necessary
		imm64[0] ^= imm64[7];
		imm64[7] ^= imm64[0];
		imm64[0] ^= imm64[7];

		imm64[1] ^= imm64[6];
		imm64[6] ^= imm64[1];
		imm64[1] ^= imm64[6];

		imm64[2] ^= imm64[5];
		imm64[5] ^= imm64[2];
		imm64[2] ^= imm64[5];

		imm64[3] ^= imm64[4];
		imm64[4] ^= imm64[3];
		imm64[3] ^= imm64[4];*/

		return val;
	}

	void writeMem8(ulong addr, ubyte val)
	{
		if (translateAddr(addr) >= ramlen) {
			// exception
			return 0;
		}

		ram[translateAddr(addr)] = val;
	}

	void writeMem16(ulong addr, ushort val)
	{
		if (translateAddr(addr) + 1 >= ramlen) {
			// exception
			return 0;
		}

		//writefln("addr: %x", translateAddr(addr));

		/*ubyte* imm64 = cast(ubyte*)&val;

		// switch immediate	if necessary
		imm64[0] ^= imm64[1];
		imm64[1] ^= imm64[0];
		imm64[0] ^= imm64[1];*/

		*cast(ushort*)&ram[translateAddr(addr)] = val;
	}

	void writeMem32(ulong addr, uint val)
	{
		if (translateAddr(addr) + 3 >= ramlen) {
			// exception
			return 0;
		}

		/*ubyte* imm64 = cast(ubyte*)&val;

		// switch immediate	if necessary
		imm64[0] ^= imm64[3];
		imm64[3] ^= imm64[0];
		imm64[0] ^= imm64[3];

		imm64[1] ^= imm64[2];
		imm64[2] ^= imm64[1];
		imm64[1] ^= imm64[2];*/

		*cast(uint*)&ram[translateAddr(addr)] = val;
	}

	void writeMem64(ulong addr, ulong val)
	{
		if (translateAddr(addr) + 7 >= ramlen) {
			// exception
			return 0;
		}

		/*ubyte* imm64 = cast(ubyte*)&val;

		// switch immediate	if necessary
		imm64[0] ^= imm64[7];
		imm64[7] ^= imm64[0];
		imm64[0] ^= imm64[7];

		imm64[1] ^= imm64[6];
		imm64[6] ^= imm64[1];
		imm64[1] ^= imm64[6];

		imm64[2] ^= imm64[5];
		imm64[5] ^= imm64[2];
		imm64[2] ^= imm64[5];

		imm64[3] ^= imm64[4];
		imm64[4] ^= imm64[3];
		imm64[3] ^= imm64[4];*/

		*cast(ulong*)&ram[translateAddr(addr)] = val;
	}



	/*
		SegES = 1,
		SegCS = 2,
		SegSS = 4,
		SegDS = 8,
		SegFS = 16,
		SegGS = 32,*/

	register* segmentRegisters[33] = [1: &es, 2: &cs, 4: &ss, 8: &ds, 16: &fs, 32: &gs];


	ulong translateSeg(ulong addr, Prefix pfix)
	{
		ulong val = segmentRegisters[pfix & 0x1f].i64;
		val <<= 4;
		val += addr;

		return val;
	}

	ubyte readSeg8(ulong addr, Prefix pfix)
	{
		if (translateSeg(addr, pfix) >= ramlen)
		{
			// exception
			return 0;
		}

		ubyte val = *(cast(ubyte*)&ram[translateSeg(addr, pfix)]);

		return val;
	}

	ushort readSeg16(ulong addr, Prefix pfix)
	{
		if (translateSeg(addr, pfix) + 1 >= ramlen)
		{
			// exception
			return 0;
		}
		//writefln("addr: %x", translateSeg(addr, pfix));

		ushort val = *(cast(ushort*)&ram[translateSeg(addr, pfix)]);
		/*ubyte* imm64 = cast(ubyte*)&val;

		// switch immediate	if necessary
		imm64[0] ^= imm64[1];
		imm64[1] ^= imm64[0];
		imm64[0] ^= imm64[1];*/

		return val;
	}

	uint readSeg32(ulong addr, Prefix pfix)
	{
		if (translateSeg(addr, pfix) + 3 >= ramlen)
		{
			// exception
			return 0;
		}

		uint val = *(cast(uint*)&ram[translateSeg(addr, pfix)]);
		/*ubyte* imm64 = cast(ubyte*)&val;

		// switch immediate	if necessary
		imm64[0] ^= imm64[3];
		imm64[3] ^= imm64[0];
		imm64[0] ^= imm64[3];

		imm64[1] ^= imm64[2];
		imm64[2] ^= imm64[1];
		imm64[1] ^= imm64[2];*/

		return val;
	}

	ulong readSeg64(ulong addr, Prefix pfix)
	{
		if (translateSeg(addr, pfix) + 7 >= ramlen)
		{
			// exception
			return 0;
		}

		ulong val = *(cast(ulong*)&ram[translateSeg(addr, pfix)]);
		/*ubyte* imm64 = cast(ubyte*)&val;

		// switch immediate	if necessary
		imm64[0] ^= imm64[7];
		imm64[7] ^= imm64[0];
		imm64[0] ^= imm64[7];

		imm64[1] ^= imm64[6];
		imm64[6] ^= imm64[1];
		imm64[1] ^= imm64[6];

		imm64[2] ^= imm64[5];
		imm64[5] ^= imm64[2];
		imm64[2] ^= imm64[5];

		imm64[3] ^= imm64[4];
		imm64[4] ^= imm64[3];
		imm64[3] ^= imm64[4];*/

		return val;
	}

	void writeSeg8(ulong addr, ubyte val, Prefix pfix)
	{
		if (translateSeg(addr, pfix) >= ramlen) {
			// exception
			return 0;
		}

		ram[translateSeg(addr, pfix)] = val;
	}

	void writeSeg16(ulong addr, ushort val, Prefix pfix)
	{
		if (translateSeg(addr, pfix) + 1 >= ramlen) {
			// exception
			return 0;
		}

		//writefln("addr: %x", translateSeg(addr, pfix));

		/*ubyte* imm64 = cast(ubyte*)&val;

		// switch immediate	if necessary
		imm64[0] ^= imm64[1];
		imm64[1] ^= imm64[0];
		imm64[0] ^= imm64[1];*/

		*cast(ushort*)&ram[translateSeg(addr, pfix)] = val;
	}

	void writeSeg32(ulong addr, uint val, Prefix pfix)
	{
		if (translateSeg(addr, pfix) + 3 >= ramlen) {
			// exception
			return 0;
		}

		/*ubyte* imm64 = cast(ubyte*)&val;

		// switch immediate	if necessary
		imm64[0] ^= imm64[3];
		imm64[3] ^= imm64[0];
		imm64[0] ^= imm64[3];

		imm64[1] ^= imm64[2];
		imm64[2] ^= imm64[1];
		imm64[1] ^= imm64[2];*/

		*cast(uint*)&ram[translateSeg(addr, pfix)] = val;
	}

	void writeSeg64(ulong addr, ulong val, Prefix pfix)
	{
		if (translateSeg(addr, pfix) + 7 >= ramlen) {
			// exception
			return 0;
		}

		/*ubyte* imm64 = cast(ubyte*)&val;

		// switch immediate	if necessary
		imm64[0] ^= imm64[7];
		imm64[7] ^= imm64[0];
		imm64[0] ^= imm64[7];

		imm64[1] ^= imm64[6];
		imm64[6] ^= imm64[1];
		imm64[1] ^= imm64[6];

		imm64[2] ^= imm64[5];
		imm64[5] ^= imm64[2];
		imm64[2] ^= imm64[5];

		imm64[3] ^= imm64[4];
		imm64[4] ^= imm64[3];
		imm64[3] ^= imm64[4];*/

		*cast(ulong*)&ram[translateSeg(addr, pfix)] = val;
	}








	ulong translateStack(ulong addr)
	{
		ulong val = ss.i64;
		val <<= 4;
		val += addr;

		return val;
	}

	ubyte readStack8(ulong addr)
	{
		if (translateStack(addr) >= ramlen)
		{
			// exception
			return 0;
		}

		ubyte val = *(cast(ubyte*)&ram[translateStack(addr)]);

		return val;
	}

	ushort readStack16(ulong addr)
	{
		if (translateStack(addr) + 1 >= ramlen)
		{
			// exception
			return 0;
		}
		//writefln("addr: %x", translateStack(addr));

		ushort val = *(cast(ushort*)&ram[translateStack(addr)]);
		/*ubyte* imm64 = cast(ubyte*)&val;

		// switch immediate	if necessary
		imm64[0] ^= imm64[1];
		imm64[1] ^= imm64[0];
		imm64[0] ^= imm64[1];*/

		return val;
	}

	uint readStack32(ulong addr)
	{
		if (translateStack(addr) + 3 >= ramlen)
		{
			// exception
			return 0;
		}

		uint val = *(cast(uint*)&ram[translateStack(addr)]);
		/*ubyte* imm64 = cast(ubyte*)&val;

		// switch immediate	if necessary
		imm64[0] ^= imm64[3];
		imm64[3] ^= imm64[0];
		imm64[0] ^= imm64[3];

		imm64[1] ^= imm64[2];
		imm64[2] ^= imm64[1];
		imm64[1] ^= imm64[2];*/

		return val;
	}

	ulong readStack64(ulong addr)
	{
		if (translateStack(addr) + 7 >= ramlen)
		{
			// exception
			return 0;
		}

		ulong val = *(cast(ulong*)&ram[translateStack(addr)]);
		/*ubyte* imm64 = cast(ubyte*)&val;

		// switch immediate	if necessary
		imm64[0] ^= imm64[7];
		imm64[7] ^= imm64[0];
		imm64[0] ^= imm64[7];

		imm64[1] ^= imm64[6];
		imm64[6] ^= imm64[1];
		imm64[1] ^= imm64[6];

		imm64[2] ^= imm64[5];
		imm64[5] ^= imm64[2];
		imm64[2] ^= imm64[5];

		imm64[3] ^= imm64[4];
		imm64[4] ^= imm64[3];
		imm64[3] ^= imm64[4];*/

		return val;
	}

	void writeStack8(ulong addr, ubyte val)
	{
		if (translateStack(addr) >= ramlen) {
			// exception
			return 0;
		}

		ram[translateStack(addr)] = val;
	}

	void writeStack16(ulong addr, ushort val)
	{
		if (translateStack(addr) + 1 >= ramlen) {
			// exception
			return 0;
		}

		//writefln("addr: %x", translateStack(addr));

		/*ubyte* imm64 = cast(ubyte*)&val;

		// switch immediate	if necessary
		imm64[0] ^= imm64[1];
		imm64[1] ^= imm64[0];
		imm64[0] ^= imm64[1];*/

		*cast(ushort*)&ram[translateStack(addr)] = val;
	}

	void writeStack32(ulong addr, uint val)
	{
		if (translateStack(addr) + 3 >= ramlen) {
			// exception
			return 0;
		}

		/*ubyte* imm64 = cast(ubyte*)&val;

		// switch immediate	if necessary
		imm64[0] ^= imm64[3];
		imm64[3] ^= imm64[0];
		imm64[0] ^= imm64[3];

		imm64[1] ^= imm64[2];
		imm64[2] ^= imm64[1];
		imm64[1] ^= imm64[2];*/

		*cast(uint*)&ram[translateStack(addr)] = val;
	}

	void writeStack64(ulong addr, ulong val)
	{
		if (translateStack(addr) + 7 >= ramlen) {
			// exception
			return 0;
		}

		/*ubyte* imm64 = cast(ubyte*)&val;

		// switch immediate	if necessary
		imm64[0] ^= imm64[7];
		imm64[7] ^= imm64[0];
		imm64[0] ^= imm64[7];

		imm64[1] ^= imm64[6];
		imm64[6] ^= imm64[1];
		imm64[1] ^= imm64[6];

		imm64[2] ^= imm64[5];
		imm64[5] ^= imm64[2];
		imm64[2] ^= imm64[5];

		imm64[3] ^= imm64[4];
		imm64[4] ^= imm64[3];
		imm64[3] ^= imm64[4];*/

		*cast(ulong*)&ram[translateStack(addr)] = val;
	}
}

