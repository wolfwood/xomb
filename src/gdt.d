module gdt;

import util;

enum SysSegType64
{
	LDT = 0b0010,
	AvailTSS = 0b1001,
	BusyTSS = 0b1011,
	CallGate = 0b1100,
	IntGate = 0b1110,
	TrapGate = 0b1111
}

align(1) struct CodeSegDesc64
{
	uint zero0 = 0;
	ubyte zero1 = 0;
	ubyte flags1 = 0b0001_1000;
	ubyte flags2;
	ubyte zero2 = 0;

	mixin(Bitfield!(flags1, "zero3", 2, "c", 1, "ones0", 2, "dpl", 2, "p", 1));
	mixin(Bitfield!(flags2, "zero4", 5, "l", 1, "d", 1, "zero5", 1));
}

static assert(CodeSegDesc64.sizeof == 8);

align(1) struct DataSegDesc64
{
	uint zero0 = 0;
	ubyte zero1 = 0;
	ubyte flags = 0b0001_0000;
	ushort zero2 = 0;

	mixin(Bitfield!(flags, "zero3", 7, "p", 1));
}

static assert(DataSegDesc64.sizeof == 8);

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


/* TSS structure.  Though we won't use the TSS for task switching,
 * we still need one for some lame ass reason.
 */
align(1) struct TSSstructure
{
	uint reserved0;				// Reserved space
	ulong rsp0;					// Three longs for RSP address
	ulong rsp1;					// w00t
	ulong rsp2;					// pew pew
	
	ulong reserved1;			// More reserved space
	ulong ist1;					// IST space (space for seven)
	ulong ist2;
	ulong ist3;
	ulong ist4;
	ulong ist5;
	ulong ist6;
	ulong ist7;
	
	ulong reserved2;			// More reserved space again
	
	ushort reserved3;			// More reserved space again...
	ushort iomap;				// IO mapped base address
}

TSSstructure tss_struct;		// Create an instance of the tss

// Special pointer which includes the limit: The max bytes
// taken up by the GDT, minus 1. Again, this NEEDS to be packed
align(1) struct GDTPtr
{
	ushort limit;
	ulong base;
}

extern(C) GDTPtr gp;

// Since an entry can be 8 or 16 bytes long, we have to do some scary shit to make this
// work right.  Pointer hacking and such.
public ulong[64] Entries;

void setCodeSegment64(int num, bool conforming, ubyte DPL, bool present, bool longMode, bool opSize)
{
	if(longMode)
		assert(opSize is false, "GDT.setCodeSegment -- If long mode, opSize must be false!");

	CodeSegDesc64 cs;
	
	with(cs)
	{
		c = conforming;
		dpl = DPL;
		p = present;
		l = longMode;
		d = opSize;
	}
	
	*cast(CodeSegDesc64*)&Entries[num] = cs;
}

void setDataSegment64(int num, bool present)
{
	DataSegDesc64 ds;

	with(ds)
	{
		p = present;
	}
	
	*cast(DataSegDesc64*)&Entries[num] = ds;
}

void setSysSegment64(int num, uint limit, ulong base, SysSegType64 segType, ubyte DPL, bool present, bool avail, uint granularity)
{
	SysSegDesc64 ss;

	with(ss)
	{
		base_lo = (base & 0xFFFF);
		base_midlo = (base >> 16) & 0xFF;
		base_midhi = (base >> 24) & 0xFF;
		base_hi = (base >> 32) & 0xFFFF;

		limit_lo = limit & 0xFFFF;
		limit_hi = (limit >> 16) & 0xF;

		type = segType;
		dpl = DPL;
		p = present;
		avl = avail;
		g = granularity;
	}
	
	*cast(SysSegDesc64*)&Entries[num] = ss;
}

void setNull(int num)
{
	Entries[num] = 0;
}

void install()
{
	gp.limit = (typeof(Entries[0]).sizeof * Entries.length) - 1;
	gp.base = cast(ulong)Entries.ptr;

	setNull(0);
	setNull(1);
	setCodeSegment64(2, true, 0, true, true, false);
	setDataSegment64(3, true);
	setDataSegment64(4, true);
	setSysSegment64(6, 0x67, cast(ulong)&tss_struct, SysSegType64.AvailTSS, 0, true, false, 0);

	// for SYSCALL and SYSRET
	setDataSegment64(8, true);
	setCodeSegment64(9, true, 3, true, true, false);

	// WTF do we set the RSP0-2 members to?!
	//tss_struct.rsp0 = tss_struct.rsp1 = tss_struct.rsp2 =

	asm
	{
		"lgdt (gp)";
		"movw $0x30, %%ax" ::: "ax";
		"ltr %%ax";
	}
}