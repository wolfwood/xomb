module kernel.arch.x86_64.descriptors;

import kernel.core.util;

/**
The various kinds of system segment types.
*/
enum SysSegType64
{
	/**
	Local descriptor table.
	*/
	LDT = 0b0010,
	
	/**
	Available task state selector.
	*/
	AvailTSS = 0b1001,
	
	/**
	Busy task state selector.
	*/
	BusyTSS = 0b1011,

	/**
	System call gate.
	*/
	CallGate = 0b1100,
	
	/**
	Interrupt gate.
	*/
	IntGate = 0b1110,
	
	/**
	Trap gate.
	*/
	TrapGate = 0b1111
}

/**
A struct that represents a code segment descriptor in 64-bit mode.
*/
align(1) struct CodeSegDesc64
{
	uint zero0 = 0x0000ffff;
	ubyte zero1 = 0;
	ubyte flags1 = 0b11111101;
	ubyte flags2 = 0;//0xaf;
	ubyte zero2 = 0;

	mixin(Bitfield!(flags1, "zero3", 2, "c", 1, "ones0", 2, "dpl", 2, "p", 1));
	mixin(Bitfield!(flags2, "zero4", 5, "l", 1, "d", 1, "zero5", 1));
}

static assert(CodeSegDesc64.sizeof == 8);

/**
A struct that represents a data segment descriptor in 64-bit mode.
*/
align(1) struct DataSegDesc64
{
	uint zero0 = 0x0000ffff;
	ubyte zero1 = 0;
	ubyte flags = 0b11110011;
	ubyte zero2 = 0xcf;
	ubyte zero3 = 0;

	mixin(Bitfield!(flags, "zero4", 5, "dpl", 2, "p", 1));
}

static assert(DataSegDesc64.sizeof == 8);

/**
A struct that represents a system segment descriptor in 64-bit mode.
*/
align(1) struct SysSegDesc64
{
	ushort limit_lo;
	ushort base_lo;
	ubyte base_midlo;
	ubyte flags1;
	ubyte flags2;
	ubyte base_midhi;
	uint base_hi;
	uint reserved = 0;

	mixin(Bitfield!(flags1, "type", 4, "zero0", 1, "dpl", 2, "p", 1));
	mixin(Bitfield!(flags2, "limit_hi", 4, "avl", 1, "zero1", 2, "g", 1));
}

static assert(SysSegDesc64.sizeof == 16);

/**
A struct that represents a call gate descriptor in 64-bit mode.
*/
align(1) struct CallGateDesc64
{
	ushort target_lo;
	ushort selector;
	ushort flags;
	ushort target_mid;
	uint target_hi;
	uint reserved = 0;
	
	mixin(Bitfield!(flags, "zero0", 8, "type", 4, "zero1", 1, "dpl", 2, "p", 1));
}

static assert(CallGateDesc64.sizeof == 16);

/**
A struct that represents a interrupt gate descriptor in 64-bit mode.
*/
align(1) struct IntGateDesc64
{
	ushort target_lo;
	ushort segment;
	ushort flags;
	ushort target_mid;
	uint target_hi;
	uint reserved = 0;

	mixin(Bitfield!(flags, "ist", 3, "zero0", 5, "type", 4, "zero1", 1, "dpl", 2, "p", 1));
}

static assert(IntGateDesc64.sizeof == 16);


