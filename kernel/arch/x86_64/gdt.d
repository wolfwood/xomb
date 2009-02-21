/**
This module holds all the functionality relating to the GDT (the Global Descriptor
Table).  This is an outdated table from the 16-bit era that has somehow been preserved
in X86-64 for some bizarre reason.  Most of the functionality of the GDT is not even
used in 64-bit mode, and some functionality is just redefined.

All of the functions used for setting entries in the GDT take an index into the table.
That index is defined as a multiple of 8-byte entries, regardless of the size of the
entry you're setting.  So, if you set a 16-byte entry into index 3, slots 3 and 4 will
be taken up by it, making the next valid index 5.
*/
module kernel.arch.x86_64.gdt;

import kernel.arch.x86_64.vmem;
import kernel.arch.x86_64.descriptors;

import kernel.core.util;
import kernel.dev.vga;


struct GDT
{

static:
private:

/**
TSS structure.  Though we won't use the TSS for task switching,
we still need one for some lame ass reason.  THANKS AMD.
*/
align(1) struct TSSstructure
{
	uint reserved0;				// Reserved space
	ulong rsp0 = vMem.REGISTER_STACK;					// Three longs for RSP address
	ulong rsp1;					// w00t
	ulong rsp2;					// pew pew

	ulong reserved1;			// More reserved space
	ulong ist1;// = vMem.REGISTER_STACK;					// IST space (space for seven)
	ulong ist2;
	ulong ist3;
	ulong ist4;
	ulong ist5;
	ulong ist6;
	ulong ist7 = vMem.REGISTER_STACK;
	
	ulong reserved2;			// More reserved space again
	
	ushort reserved3;			// More reserved space again...
	ushort iomap;				// IO mapped base address
}


TSSstructure tss_struct;		// Create an instance of the tss

/**
This is a "pointer" structure which consists of a limit (size - 1) and base
(address) of where the GDT is located.  This is what is loaded by the LGDT
instruction.
*/
align(1) struct GDTPtr
{
	ushort limit;
	ulong base;
}

/**
The GDT data itself.  Since an entry can be 8 or 16 bytes long (THANKS INTEL AND AMD),
we have to do some scary shit to make this work right.  Pointer hacking and such.
*/
private ulong[64] Entries;

/**
Set a 64-bit code segment.  Code segment descriptors only take up one slot.

Params:
	num = The entry index.  See the module description.
	conforming = Whether the segment is conforming.  Has to do with CPL bullshit that we don't
		really care about in 64-bit mode.  I think we just set it to 'true'.
	DPL = Descriptor privilege level.  Again, segmentation crap that we don't care about but
		for some reason we still need to mess with.  0 is system, 3 is user, anywhere in between is kind
		of useless.
	present = Whether or not the segment is loaded into memory.
*/
void setCodeSegment64(int num, bool conforming, ubyte DPL, bool present)
{
	CodeSegDesc64 cs;

	with(cs)
	{
		c = conforming;
		dpl = DPL;
		p = present;
		l = true;
		d = false;
	}

	*cast(CodeSegDesc64*)&Entries[num] = cs;
}

/**
Set a 64-bit data segment.  Data segment descriptors only take up one slot.
These are a testament to "why does this stuff even exist in 64 bit mode?".

Three bits are significant! The present bit and the DPL.  (used by IRETQ apparently)

Params:
	num = The entry index.  See the module description.
	present = Whether or not the segment is loaded into memory.
*/
void setDataSegment64(int num, bool present, ubyte DPL)
{
	DataSegDesc64 ds;

	with(ds)
	{
		p = present;
		dpl = DPL;
	}
	
	*cast(DataSegDesc64*)&Entries[num] = ds;
}

/**
Set a 64-bit system segment.  System segment descriptors take up two slots.  System
segment descriptors are, in 64-bit, used for LDTs, TSSes, call gates, interrupt gates,
and trap gates.  We don't use any of these, except the TSS, which the processor wants
to use for $(I something).  I'm not sure what.

Params:
	num = The entry index.  See the module description.
	limit = The size of the segment.
	segType = The type of the segment.  See the SysSegType64 enum.
	DPL = Descriptor privilege level.  0 is system, 3 is user, anywhere in between is
		kind of useless.
	present = Whether or not the segment is loaded into memory.
	avail = Just a bit available for use by the OS.  The processor never touches this bit.
	granularity = If false, limit field is unscaled.  If true, limit field is scaled by 4KB.

*/
void setSysSegment64(int num, uint limit, ulong base, SysSegType64 segType, ubyte DPL, bool present, bool avail, bool granularity)
{
	SysSegDesc64 ss;

	with(ss)
	{
		base_lo = (base & 0xFFFF);
		base_midlo = (base >> 16) & 0xFF;
		base_midhi = (base >> 24) & 0xFF;
		base_hi = (base >> 32) & 0xFFFFFFFF;

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

/**
Nulls out a single 8-byte slot in the GDT.  Useful for i.e. the first entry, which always
has to be a null descriptor.

Params:
	num = The entry index.  See the module description.
*/
void setNull(int num)
{
	Entries[num] = 0;
}

/**
Set up and install the default GDT.
*/
public void install()
{
	gp.limit = (typeof(Entries[0]).sizeof * Entries.length) - 1;
	gp.base = cast(ulong)Entries.ptr;

	setNull(0);
	setNull(1);
	setCodeSegment64(2, false, 0, true);
	setDataSegment64(3, true, 0);
	setDataSegment64(4, true, 0);
	setSysSegment64(6, 0x67, (cast(ulong)&tss_struct), SysSegType64.AvailTSS, 0, true, false, false);

	// for SYSCALL and SYSRET
	setDataSegment64(8, true, 3);
	setCodeSegment64(9, true, 3, true);

	// WTF do we set the RSP0-2 members to?!
	//tss_struct.rsp0 = tss_struct.rsp1 = tss_struct.rsp2 =
	//asm {
	//	"movq %%rsp, %%rax" ::: "rax";
	//	"movq %%rax, %0" :: "o" tss_struct.ist1 : "rax";
	//}/
	setGDT();

	// set task register
	// XXX: Why does it restart if I do this on an AP?
	// XXX: answer: probably another bug due to bad setting of base address in the gdt
	//    :       : it will probably work now
	asm
	{
		"movw $0x30, %%ax" ::: "ax";
		"ltr %%ax";
	}
}

public void setGDT()
{
	asm
	{
		"lgdt (gp)";
	}
}

}

/**
The pointer to the GDT that we use when do do LGDT.
*/
private extern(C) GDT.GDTPtr gp;


