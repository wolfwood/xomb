module xombemu.x86.registers;

import util;

import std.stdio;

enum Register:ushort
{

	// reg8
	AL,
	CL,
	DL,
	BL,
	AH,
	CH,
	DH,
	BH,

	//reg16
	AX,
	CX,
	DX,
	BX,
	SP,
	BP,
	SI,
	DI,

	//reg32
	EAX,
	ECX,
	EDX,
	EBX,
	ESP,
	EBP,
	ESI,
	EDI,

	//reg64
	RAX,
	RCX,
	RDX,
	RBX,
	RSP,
	RBP,
	RSI,
	RDI,
	R8,
	R9,
	R10,
	R11,
	R12,
	R13,
	R14,
	R15,

	// program counter
	RIP,

	// etc
	RFLAGS,

	// system
	ES,
	CS,
	SS,
	DS,
	FS,
	GS,

	// control
	CR0,
	CR1,
	CR2,
	CR3,
	CR4,
	CR5,
	CR6,
	CR7,

	// debug
	DR0,
	DR1,
	DR2,
	DR3,
	DR4,
	DR5,
	DR6,
	DR7,

	//mmx
	MMX0,
	MMX1,
	MMX2,
	MMX3,
	MMX4,
	MMX5,
	MMX6,
	MMX7,

	//xmm
	XMM0,
	XMM1,
	XMM2,
	XMM3,
	XMM4,
	XMM5,
	XMM6,
	XMM7,

	// processor
	IDTR,
}

char[][] registerNames = [

	//reg8
	"al",
	"cl",
	"dl",
	"bl",
	"ah",
	"ch",
	"dh",
	"bh",

	//reg16
	"ax",
	"cx",
	"dx",
	"bx",
	"sp",
	"bp",
	"si",
	"di",

	//reg32
	"eax",
	"ecx",
	"edx",
	"ebx",
	"esp",
	"ebp",
	"esi",
	"edi",

	//reg64
	"rax",
	"rcx",
	"rdx",
	"rbx",
	"rsp",
	"rbp",
	"rsi",
	"rdi",

	"r8",
	"r9",
	"r10",
	"r11",
	"r12",
	"r13",
	"r14",
	"r15",

	// program counter
	"rip",

	// etc
	"rflags",

	// system
	"es",
	"cs",
	"ss",
	"ds",
	"fs",
	"gs",

	// control
	"cr0",
	"cr1",
	"cr2",
	"cr3",
	"cr4",
	"cr5",
	"cr6",
	"cr7",

	// debug
	"dr0",
	"dr1",
	"dr2",
	"dr3",
	"dr4",
	"dr5",
	"dr6",
	"dr7",

	//mmx
	"mmx0",
	"mmx1",
	"mmx2",
	"mmx3",
	"mmx4",
	"mmx5",
	"mmx6",
	"mmx7",

	//xmm
	"xmm0",
	"xmm1",
	"xmm2",
	"xmm3",
	"xmm4",
	"xmm5",
	"xmm6",
	"xmm7",

	// processor
	"idtr",
];




union flags
{
	ulong i64 = 0b0000_0000_0000_0000_0000_0000_0000_0010;

	mixin(Bitfield!(i64,
		"carry", 1, 			// carry
		"reserved1", 1, 		// keep as 1
		"parity", 1,			// parity
		"reserved2", 1,			// keep as 0
		"aux", 1,				// auxiliary
		"reserved3", 1,			// keep as 0
		"zero", 1,				// zero
		"sign", 1,				// sign
		"trap", 1,				// trap
		"interrupt", 1,			// interrupt
		"direction", 1,			// direction
		"overflow", 1,			// overflow
		"IOPL", 2,				// IO Privilege Level
		"nested", 1,			// nested task
		"reserved4", 1,			// keep as 0
		"resume", 1,			// resume
		"v86", 1,				// virtual-8086 mode
		"alignment", 1,			// alignment check
		"vif", 1,				// virtual int flag
		"vip", 1,				// virtual int pending
		"id", 1					// ID flag
		));

		// the rest are zero
}

union register
{
	ubyte[8] b;

	ubyte i8;
	ushort i16;
	uint i32;
	ulong i64;

	void high(ubyte val)
	{
		b[1] = val;
	}

	ubyte high()
	{
		return b[1];
	}

	void low(ubyte val)
	{
		i8 = val;
	}

	ubyte low()
	{
		return i8;
	}
}

register rax;
register rcx;
register rdx;
register rbx;
register rsp;
register rbp;
register rdi;
register rsi;

register r8;
register r9;
register r10;
register r11;
register r12;
register r13;
register r14;
register r15;

register rip;

register es;
register cs;
register ss;
register ds;
register fs;
register gs;

register cr0;
register cr1;
register cr2;
register cr3;
register cr4;
register cr5;
register cr6;
register cr7;

register dr0;
register dr1;
register dr2;
register dr3;
register dr4;
register dr5;
register dr6;
register dr7;

flags rflags;

register idtr;


register*[Register.DR7+1] registers = [&rax, &rcx, &rdx, &rbx, &rax, &rcx, &rdx, &rbx,
									 &rax, &rcx, &rdx, &rbx, &rsp, &rbp, &rsi, &rdi,
									 &rax, &rcx, &rdx, &rbx, &rsp, &rbp, &rsi, &rdi,
									 &rax, &rcx, &rdx, &rbx, &rsp, &rbp, &rsi, &rdi,
									 &r8, &r9, &r10, &r11, &r12, &r13, &r14, &r15,
									 &rip, cast(register*)&rflags,
									 &es, &cs, &ss, &ds, &fs, &gs,
									 &cr0, &cr1, &cr2, &cr3, &cr4, &cr5, &cr6, &cr7,
									 &dr0, &dr1, &dr2, &dr3, &dr4, &dr5, &dr6, &dr7,
									 // MMX //
									 // XMM //
									 ];

void setReg(Register reg, long value)
{
	if (reg < Register.AH)
	{
		// 8 bit (low)
		registers[reg].low = cast(ubyte)value;
	}
	else if (reg < Register.AX)
	{
		// 8 bit (high)
		registers[reg].high = cast(ubyte)value;
	}
	else if (reg < Register.EAX)
	{
		// 16 bit
		registers[reg].i16 = cast(ushort)value;
	}
	else if (reg < Register.RAX)
	{
		// 32 bit
		registers[reg].i32 = cast(uint)value;
	}
	else
	{
		// just set
		registers[reg].i64 = value;
	}
}

void setRegU(Register reg, ulong value)
{
	if (reg < Register.AH)
	{
		// 8 bit (low)
		registers[reg].low = cast(ubyte)value;
	}
	else if (reg < Register.AX)
	{
		// 8 bit (high)
		registers[reg].high = cast(ubyte)value;
	}
	else if (reg < Register.EAX)
	{
		// 16 bit
		registers[reg].i16 = cast(ushort)value;
	}
	else if (reg < Register.RAX)
	{
		// 32 bit
		registers[reg].i32 = cast(uint)value;
	}
	else
	{
		// just set
		registers[reg].i64 = value;
	}
}

void getReg(long reg, ref long value)
{
	if (reg < Register.AH)
	{
		// 8 bit (low)
		value = registers[reg].low;
	}
	else if (reg < Register.AX)
	{
		// 8 bit (high)
		value = registers[reg].high;
	}
	else if (reg < Register.EAX)
	{
		// 16 bit
		value = registers[reg].i16;
	}
	else if (reg < Register.RAX)
	{
		// 32 bit
		value = registers[reg].i32;
	}
	else
	{
		// just set
		value = registers[reg].i64;
	}
}

void getRegU(long reg, ref ulong value)
{
	if (reg < Register.AH)
	{
		// 8 bit (low)
		value = registers[reg].low;
	}
	else if (reg < Register.AX)
	{
		// 8 bit (high)
		value = registers[reg].high;
	}
	else if (reg < Register.EAX)
	{
		// 16 bit
		value = registers[reg].i16;
	}
	else if (reg < Register.RAX)
	{
		// 32 bit
		value = registers[reg].i32;
	}
	else
	{
		// just set
		value = registers[reg].i64;
	}
}

void printAll()
{
	foreach (uint i, reg; registers[Register.min..Register.GS+1])
	{
		if (i <= Register.RAX && ((i % 4) == 0)) { writef("\n"); }
		if (i > Register.RAX && ((i % 2) == 0)) { writef("\n"); }

		if (i < Register.AH)
		{
			// 8 bit (low)
			writef(registerNames[i], ": 0x%.2x", reg.low, "\t");
		}
		else if (i < Register.AX)
		{
			// 8 bit (high)
			writef(registerNames[i], ": 0x%.2x", reg.high, "\t");
		}
		else if (i < Register.EAX)
		{
			// 16 bit
			writef(registerNames[i], ": 0x%.4x", reg.i16, "\t");
		}
		else if (i < Register.RAX)
		{
			// 32 bit
			writef(registerNames[i], ": 0x%.8x", reg.i32, "\t");
		}
		else
		{
			// just set
			writef(registerNames[i], ": 0x%.16x", reg.i64, "\t");
		}
	}

	writef("\n");
}
