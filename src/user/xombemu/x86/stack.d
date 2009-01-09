module user.xombemu.x86.stack;

import user.xombemu.x86.registers;
import user.xombemu.x86.memory;

import std.stdio;

struct Stack
{
static:

	void init()
	{
		rsp.i64 = 0;
	}
	
	void print(uint amt)
	{
		ulong curRsp = translateRsp();
		
		for(uint i=0;i<amt;i++){		
			//writefln("0x%.4x", Memory.read16(curRsp));
			curRsp += 2;
		}
	}
	
	ulong translateRsp()
	{
		ulong val = ss.i64;
		val <<= 4;
		val += rsp.i16;
		
		return val;
	}

	// 16 bit push
	void pushW(ushort val)
	{
		rsp.i64 -= 2;
		Memory.write16(translateRsp(), val);
		//writefln("stack <= 0x%x", val);
	}

	// 32 bit push
	void pushD(uint val)
	{
		rsp.i64 -= 4;
		Memory.write32(translateRsp(), val);
	}

	// 64 bit push
	void pushQ(ulong val)
	{
		rsp.i64 -= 8;
		Memory.write64(translateRsp(), val);
	}

	// 16 bit pop
	ushort popW()
	{
		rsp.i64 += 2;
		return Memory.read16(translateRsp()-2);
	}
	
	// 32 bit pop
	ushort popD()
	{
		rsp.i64 += 4;
		return Memory.read32(translateRsp()-4);
	}

	// 64 bit pop
	ushort popQ()
	{
		rsp.i64 += 8;
		return Memory.read64(translateRsp()-8);
	}

}