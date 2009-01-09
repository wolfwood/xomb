module user.xombemu.x86.fetch;

import user.xombemu.x86.opcodes;
import user.xombemu.x86.registers;
import user.xombemu.x86.memory;

import user.util;

import std.stdio;


uint idx = 0;

bool popCode(ref ubyte opcode)
{
	opcode = Memory.readRip8();
	return true;
}

bool popImm8(ref ulong imm)
{
	imm = Memory.readRip8();
	return true;
}

bool popImm16(ref ulong imm)
{
	imm = Memory.readRip16();
	return true;
}

bool popImm32(ref ulong imm)
{
	imm = Memory.readRip32();
	return true;
}

bool popImm64(ref ulong imm)
{
	imm = Memory.readRip64();
	return true;
}

bool popDisp8(ref long disp)
{
	disp = cast(byte)Memory.readRip8();
	return true;
}

bool popDisp16(ref long disp)
{
	disp = cast(short)Memory.readRip16();
	return true;
}

bool popDisp32(ref long disp)
{
	disp = cast(int)Memory.readRip32();
	return true;
}

bool popModRM(ref ModRM modrm)
{
	return popCode(modrm.i8);
}








struct ModRM {
	ubyte i8;

	mixin(Bitfield!(i8,
		"rm", 3,
		"reg", 3,
		"mod", 2
		));
}

enum Prefix:ushort
{
	None,

	// force segment selection
	SegES = 1,
	SegCS = 2,
	SegSS = 4,
	SegDS = 8,
	SegFS = 16,
	SegGS = 32,

	Lock = 64,

	OperandSize = 128,
	AddressSize = 256,

	Rep = 512,
	Repe = 1024,
	Repne = 2048,

	// REX Prefixes ( when >= REX0000, mask for the value )

	REX0000 = 4096,
	REX0001,
	REX0010,
	REX0011,
	REX0100,
	REX0101,
	REX0110,
	REX0111,

	REX1000,
	REX1001,
	REX1010,
	REX1011,
	REX1100,
	REX1101,
	REX1110,
	REX1111,

}

enum Access:ushort {
	Null,		// operand is unused
	Addr,		// operand is an address
	Offset,		// operand is an offset (reg + displacement)
	OffsetSI,	//
	OffsetDI,	//
	Offset0,	//
	Reg,		// operand is a register
	Imm8,		// operand is an immediate
	Imm16,
	Imm32,
	Imm64,
	Mem,		// operand is a memory offset
}

enum WordSize {
	b8,
	b16,
	b32,
}

const Register baseReg[] = [Register.AL, Register.AX, Register.EAX];

enum FieldType:ushort
{
	None = Register.max,		// none

	// IMMEDIATE

	Imm,						// effective immediate
	Immz,						// conditional immediate
	Imm8,						// 8 bit immediate
	Imm16,						// 16 bit immediate
	Imm32,						// 32 bit immediate
	Imm64,						// 64 bit immediate

	// REQUIRE MODRM:

	Reg,						// reg field used
	Regz,
	Reg8,
	Reg16,
	Reg32,

	Rm,							// rm field used
	Rmz,
	Rm8,
	Rm16,
	Rm32,

	// MEMORY OPERAND FROM MODRM

	Mem,
	Mem8,
	Mem16,
	Mem32,
	Mem64,

	// CONDITIONALLY DO MEM, IF MOD=3, TAKE RM REGISTER

	MemRm,
	Mem8Rm,
	Mem16Rm,
	Mem32Rm,
	Mem64Rm,

	// SEGMENT REGISTERS

	Segment,

	// FAR POINTER

	FarPtr,

	// VALUES

	One,

}

// 2-byte opcodes
template Fetch2nd1632(ubyte opcode)
{
	const char[] Fetch2nd1632 = `
		case ` ~ Itoh!(opcode) ~ `:

			if(!popCode(opcode)) { return false; }

			switch(opcode) { ` ~

				// 2nd level opcode fetch
				Fetch!(0x80, FieldType.None, FieldType.Immz, Opcode.Jo) ~
				Fetch!(0x81, FieldType.None, FieldType.Immz, Opcode.Jno) ~
				Fetch!(0x82, FieldType.None, FieldType.Immz, Opcode.Jb) ~
				Fetch!(0x83, FieldType.None, FieldType.Immz, Opcode.Jnb) ~
				Fetch!(0x84, FieldType.None, FieldType.Immz, Opcode.Jz) ~
				Fetch!(0x85, FieldType.None, FieldType.Immz, Opcode.Jnz) ~
				Fetch!(0x86, FieldType.None, FieldType.Immz, Opcode.Jbe) ~
				Fetch!(0x87, FieldType.None, FieldType.Immz, Opcode.Jnbe) ~

				Fetch!(0xa0, FieldType.None, Register.FS, Opcode.Push) ~
				Fetch!(0xa1, Register.FS, FieldType.None, Opcode.Pop) ~
				Fetch!(0xa2, FieldType.None, FieldType.None, Opcode.Cpuid) ~
				Fetch!(0xa3, FieldType.Rm, FieldType.Reg, Opcode.Bt) ~

			`
				default:

					op = Opcode.Null;
					accSrc = Access.Null;
					accDst = Access.Null;
					accThree = Access.Null;
					break;

			}

			break;
	`;
}

// opcode fetch 16-32bit
template Fetch1632()
{
	const char[] Fetch1632 = `

		switch(opcode) {

	` ~

		Fetch!(0x00, FieldType.Rm8, FieldType.Reg8, Opcode.Add) ~
		Fetch!(0x01, FieldType.Rm, FieldType.Reg, Opcode.Add) ~
		Fetch!(0x02, FieldType.Reg8, FieldType.Rm8, Opcode.Add) ~
		Fetch!(0x03, FieldType.Reg, FieldType.Rm, Opcode.Add) ~
		Fetch!(0x04, Register.AL, FieldType.Imm8, Opcode.Add) ~
		Fetch!(0x05, Register.RAX, FieldType.Immz, Opcode.Add) ~
		Fetch!(0x06, FieldType.None, Register.ES, Opcode.Push) ~
		Fetch!(0x07, Register.ES, FieldType.None, Opcode.Pop) ~
		// --------------------------------------------------- //
		Fetch!(0x08, FieldType.Rm8, FieldType.Reg8, Opcode.Or) ~
		Fetch!(0x09, FieldType.Rm, FieldType.Reg, Opcode.Or) ~
		Fetch!(0x0a, FieldType.Reg8, FieldType.Rm8, Opcode.Or) ~
		Fetch!(0x0b, FieldType.Reg, FieldType.Rm, Opcode.Or) ~
		Fetch!(0x0c, Register.AL, FieldType.Imm8, Opcode.Or) ~
		Fetch!(0x0d, Register.RAX, FieldType.Immz, Opcode.Or) ~
		Fetch!(0x0e, FieldType.None, Register.CS, Opcode.Push) ~
		Fetch2nd1632!(0x0f) ~ // -- 2 byte opcodes -- //
		// --------------------------------------------------- //
		Fetch!(0x10, FieldType.Rm8, FieldType.Reg8, Opcode.Adc) ~
		Fetch!(0x11, FieldType.Rm, FieldType.Reg, Opcode.Adc) ~
		Fetch!(0x12, FieldType.Reg8, FieldType.Rm8, Opcode.Adc) ~
		Fetch!(0x13, FieldType.Reg, FieldType.Rm, Opcode.Adc) ~
		Fetch!(0x14, Register.AL, FieldType.Imm8, Opcode.Adc) ~
		Fetch!(0x15, Register.RAX, FieldType.Immz, Opcode.Adc) ~
		Fetch!(0x16, FieldType.None, Register.SS, Opcode.Push) ~
		Fetch!(0x17, Register.SS, FieldType.None, Opcode.Pop) ~
		// --------------------------------------------------- //
		Fetch!(0x18, FieldType.Rm8, FieldType.Reg8, Opcode.Sbb) ~
		Fetch!(0x19, FieldType.Rm, FieldType.Reg, Opcode.Sbb) ~
		Fetch!(0x1a, FieldType.Reg8, FieldType.Rm8, Opcode.Sbb) ~
		Fetch!(0x1b, FieldType.Reg, FieldType.Rm, Opcode.Sbb) ~
		Fetch!(0x1c, Register.AL, FieldType.Imm8, Opcode.Sbb) ~
		Fetch!(0x1d, Register.RAX, FieldType.Immz, Opcode.Sbb) ~
		Fetch!(0x1e, FieldType.None, Register.DS, Opcode.Push) ~
		Fetch!(0x1f, Register.DS, FieldType.None, Opcode.Pop) ~
		// --------------------------------------------------- //
		Fetch!(0x20, FieldType.Rm8, FieldType.Reg8, Opcode.And) ~
		Fetch!(0x21, FieldType.Rm, FieldType.Reg, Opcode.And) ~
		Fetch!(0x22, FieldType.Reg8, FieldType.Rm8, Opcode.And) ~
		Fetch!(0x23, FieldType.Reg, FieldType.Rm, Opcode.And) ~
		Fetch!(0x24, Register.AL, FieldType.Imm8, Opcode.And) ~
		Fetch!(0x25, Register.RAX, FieldType.Immz, Opcode.And) ~
		PreFix!(0x26, Prefix.SegES) ~
		Fetch!(0x27, FieldType.None, FieldType.None, Opcode.Daa) ~
		// --------------------------------------------------- //
		Fetch!(0x28, FieldType.Rm8, FieldType.Reg8, Opcode.Sub) ~
		Fetch!(0x29, FieldType.Rm, FieldType.Reg, Opcode.Sub) ~
		Fetch!(0x2a, FieldType.Reg8, FieldType.Rm8, Opcode.Sub) ~
		Fetch!(0x2b, FieldType.Reg, FieldType.Rm, Opcode.Sub) ~
		Fetch!(0x2c, Register.AL, FieldType.Imm8, Opcode.Sub) ~
		Fetch!(0x2d, Register.RAX, FieldType.Immz, Opcode.Sub) ~
		PreFix!(0x2e, Prefix.SegCS) ~
		Fetch!(0x2f, FieldType.None, FieldType.None, Opcode.Das) ~
		// --------------------------------------------------- //
		Fetch!(0x30, FieldType.Rm8, FieldType.Reg8, Opcode.Xor) ~
		Fetch!(0x31, FieldType.Rm, FieldType.Reg, Opcode.Xor) ~
		Fetch!(0x32, FieldType.Reg8, FieldType.Rm8, Opcode.Xor) ~
		Fetch!(0x33, FieldType.Reg, FieldType.Rm, Opcode.Xor) ~
		Fetch!(0x34, Register.AL, FieldType.Imm8, Opcode.Xor) ~
		Fetch!(0x35, Register.RAX, FieldType.Immz, Opcode.Xor) ~
		PreFix!(0x36, Prefix.SegSS) ~
		Fetch!(0x37, FieldType.None, FieldType.None, Opcode.Aaa) ~
		// --------------------------------------------------- //
		Fetch!(0x38, FieldType.Rm8, FieldType.Reg8, Opcode.Cmp) ~
		Fetch!(0x39, FieldType.Rm, FieldType.Reg, Opcode.Cmp) ~
		Fetch!(0x3a, FieldType.Reg8, FieldType.Rm8, Opcode.Cmp) ~
		Fetch!(0x3b, FieldType.Reg, FieldType.Rm, Opcode.Cmp) ~
		Fetch!(0x3c, Register.AL, FieldType.Imm8, Opcode.Cmp) ~
		Fetch!(0x3d, Register.RAX, FieldType.Immz, Opcode.Cmp) ~
		PreFix!(0x3e, Prefix.SegDS) ~
		Fetch!(0x3f, FieldType.None, FieldType.None, Opcode.Aas) ~
		// --------------------------------------------------- //
		Fetch!(0x40, Register.EAX, FieldType.None, Opcode.Inc) ~
		Fetch!(0x41, Register.ECX, FieldType.None, Opcode.Inc) ~
		Fetch!(0x42, Register.EDX, FieldType.None, Opcode.Inc) ~
		Fetch!(0x43, Register.EBX, FieldType.None, Opcode.Inc) ~
		Fetch!(0x44, Register.ESP, FieldType.None, Opcode.Inc) ~
		Fetch!(0x45, Register.EBP, FieldType.None, Opcode.Inc) ~
		Fetch!(0x46, Register.ESI, FieldType.None, Opcode.Inc) ~
		Fetch!(0x47, Register.EDI, FieldType.None, Opcode.Inc) ~
		// --------------------------------------------------- //
		Fetch!(0x48, Register.EAX, FieldType.None, Opcode.Dec) ~
		Fetch!(0x49, Register.ECX, FieldType.None, Opcode.Dec) ~
		Fetch!(0x4a, Register.EDX, FieldType.None, Opcode.Dec) ~
		Fetch!(0x4b, Register.EBX, FieldType.None, Opcode.Dec) ~
		Fetch!(0x4c, Register.ESP, FieldType.None, Opcode.Dec) ~
		Fetch!(0x4d, Register.EBP, FieldType.None, Opcode.Dec) ~
		Fetch!(0x4e, Register.ESI, FieldType.None, Opcode.Dec) ~
		Fetch!(0x4f, Register.EDI, FieldType.None, Opcode.Dec) ~
		// --------------------------------------------------- //
		Fetch!(0x50, FieldType.None, Register.RAX, Opcode.Push) ~
		Fetch!(0x51, FieldType.None, Register.RCX, Opcode.Push) ~
		Fetch!(0x52, FieldType.None, Register.RDX, Opcode.Push) ~
		Fetch!(0x53, FieldType.None, Register.RBX, Opcode.Push) ~
		Fetch!(0x54, FieldType.None, Register.RSP, Opcode.Push) ~
		Fetch!(0x55, FieldType.None, Register.RBP, Opcode.Push) ~
		Fetch!(0x56, FieldType.None, Register.RSI, Opcode.Push) ~
		Fetch!(0x57, FieldType.None, Register.RDI, Opcode.Push) ~
		// --------------------------------------------------- //
		Fetch!(0x58, Register.RAX, FieldType.None, Opcode.Pop) ~
		Fetch!(0x59, Register.RCX, FieldType.None, Opcode.Pop) ~
		Fetch!(0x5a, Register.RDX, FieldType.None, Opcode.Pop) ~
		Fetch!(0x5b, Register.RBX, FieldType.None, Opcode.Pop) ~
		Fetch!(0x5c, Register.RSP, FieldType.None, Opcode.Pop) ~
		Fetch!(0x5d, Register.RBP, FieldType.None, Opcode.Pop) ~
		Fetch!(0x5e, Register.RSI, FieldType.None, Opcode.Pop) ~
		Fetch!(0x5f, Register.RDI, FieldType.None, Opcode.Pop) ~
		// --------------------------------------------------- //
		Fetch!(0x60, FieldType.None, FieldType.None, Opcode.PushA) ~
		Fetch!(0x61, FieldType.None, FieldType.None, Opcode.PopA) ~
		Fetch!(0x62, FieldType.Reg, FieldType.Mem, Opcode.Bound) ~
		Fetch!(0x63, FieldType.Rm16, FieldType.Reg16, Opcode.Arpl) ~
		PreFix!(0x64, Prefix.SegFS) ~
		PreFix!(0x65, Prefix.SegGS) ~
		PreFix!(0x66, Prefix.OperandSize) ~
		PreFix!(0x67, Prefix.AddressSize) ~
		// --------------------------------------------------- //
		Fetch!(0x68, FieldType.None, FieldType.Immz, Opcode.Push) ~
		Fetch3!(0x69, FieldType.Reg, FieldType.Rm, FieldType.Immz, Opcode.Imul) ~
		Fetch!(0x6a, FieldType.Reg, FieldType.Imm8, Opcode.Push) ~
		Fetch3!(0x6b, FieldType.Reg, FieldType.Rm, FieldType.Imm8, Opcode.Imul) ~
		Fetch!(0x6c, Register.DI, Register.DX, Opcode.Ins) ~
		Fetch!(0x6d, Register.RDI, Register.DX, Opcode.Ins) ~
		Fetch!(0x6e, Register.DX, Register.SI, Opcode.Outs) ~
		Fetch!(0x6f, Register.DX, Register.RSI, Opcode.Outs) ~
		// --------------------------------------------------- //
		Fetch!(0x70, FieldType.None, FieldType.Imm8, Opcode.Jo) ~
		Fetch!(0x71, FieldType.None, FieldType.Imm8, Opcode.Jno) ~
		Fetch!(0x72, FieldType.None, FieldType.Imm8, Opcode.Jb) ~
		Fetch!(0x73, FieldType.None, FieldType.Imm8, Opcode.Jnb) ~
		Fetch!(0x74, FieldType.None, FieldType.Imm8, Opcode.Jz) ~
		Fetch!(0x75, FieldType.None, FieldType.Imm8, Opcode.Jnz) ~
		Fetch!(0x76, FieldType.None, FieldType.Imm8, Opcode.Jbe) ~
		Fetch!(0x77, FieldType.None, FieldType.Imm8, Opcode.Jnbe) ~
		// --------------------------------------------------- //
		Fetch!(0x78, FieldType.None, FieldType.Imm8, Opcode.Js) ~
		Fetch!(0x79, FieldType.None, FieldType.Imm8, Opcode.Jns) ~
		Fetch!(0x7a, FieldType.None, FieldType.Imm8, Opcode.Jp) ~
		Fetch!(0x7b, FieldType.None, FieldType.Imm8, Opcode.Jnp) ~
		Fetch!(0x7c, FieldType.None, FieldType.Imm8, Opcode.Jl) ~
		Fetch!(0x7d, FieldType.None, FieldType.Imm8, Opcode.Jnl) ~
		Fetch!(0x7e, FieldType.None, FieldType.Imm8, Opcode.Jle) ~
		Fetch!(0x7f, FieldType.None, FieldType.Imm8, Opcode.Jnle) ~
		// --------------------------------------------------- //
		Fetch!(0x80, FieldType.Rm8, FieldType.Imm8, Opcode.Add, Opcode.Or, Opcode.Adc, Opcode.Sbb, Opcode.And, Opcode.Sub, Opcode.Xor, Opcode.Cmp) ~
		Fetch!(0x81, FieldType.Rm, FieldType.Immz, Opcode.Add, Opcode.Or, Opcode.Adc, Opcode.Sbb, Opcode.And, Opcode.Sub, Opcode.Xor, Opcode.Cmp) ~
		Fetch!(0x82, FieldType.Rm8, FieldType.Imm8, Opcode.Add, Opcode.Or, Opcode.Adc, Opcode.Sbb, Opcode.And, Opcode.Sub, Opcode.Xor, Opcode.Cmp) ~
		Fetch!(0x83, FieldType.Rm, FieldType.Imm8, Opcode.Add, Opcode.Or, Opcode.Adc, Opcode.Sbb, Opcode.And, Opcode.Sub, Opcode.Xor, Opcode.CmpSigned) ~
		Fetch!(0x84, FieldType.Rm8, FieldType.Reg8, Opcode.Test) ~
		Fetch!(0x85, FieldType.Rm, FieldType.Reg, Opcode.Test) ~
		Fetch!(0x86, FieldType.Rm8, FieldType.Reg8, Opcode.Xchg) ~
		Fetch!(0x87, FieldType.Rm, FieldType.Reg, Opcode.Xchg) ~
		// --------------------------------------------------- //
		Fetch!(0x88, FieldType.Rm8, FieldType.Reg8, Opcode.Mov) ~
		Fetch!(0x89, FieldType.Rm, FieldType.Reg, Opcode.Mov) ~
		Fetch!(0x8a, FieldType.Reg8, FieldType.Rm8, Opcode.Mov) ~
		Fetch!(0x8b, FieldType.Reg, FieldType.Rm, Opcode.Mov) ~
		Fetch!(0x8c, FieldType.Mem16Rm, FieldType.Segment, Opcode.Mov) ~
		Fetch!(0x8d, FieldType.Reg, FieldType.Mem, Opcode.Lea) ~
		Fetch!(0x8e, FieldType.Segment, FieldType.Rm16, Opcode.Mov) ~
		Fetch!(0x8f, FieldType.Rm, FieldType.None, Opcode.Pop, Opcode.Null, Opcode.Null, Opcode.Null, Opcode.Null, Opcode.Null, Opcode.Null, Opcode.Null) ~
		// --------------------------------------------------- //
		Fetch!(0x90, FieldType.None, FieldType.None, Opcode.Nop) ~
		Fetch!(0x91, Register.RCX, Register.RAX, Opcode.Xchg) ~
		Fetch!(0x92, Register.RDX, Register.RAX, Opcode.Xchg) ~
		Fetch!(0x93, Register.RBX, Register.RAX, Opcode.Xchg) ~
		Fetch!(0x94, Register.RSP, Register.RAX, Opcode.Xchg) ~
		Fetch!(0x95, Register.RBP, Register.RAX, Opcode.Xchg) ~
		Fetch!(0x96, Register.RSI, Register.RAX, Opcode.Xchg) ~
		Fetch!(0x97, Register.RDI, Register.RAX, Opcode.Xchg) ~
		// --------------------------------------------------- //
		Fetch!(0x98, FieldType.None, FieldType.None, Opcode.Cax) ~
		Fetch!(0x99, FieldType.None, FieldType.None, Opcode.Cdx) ~
		Fetch!(0x9a, FieldType.FarPtr, FieldType.None, Opcode.Call) ~
		Fetch!(0x9b, FieldType.None, FieldType.None, Opcode.Wait) ~
		Fetch!(0x9c, FieldType.None, FieldType.None, Opcode.PushF) ~
		Fetch!(0x9d, FieldType.None, FieldType.None, Opcode.PopF) ~
		Fetch!(0x9e, FieldType.None, FieldType.None, Opcode.Sahf) ~
		Fetch!(0x9f, FieldType.None, FieldType.None, Opcode.Lahf) ~
		// --------------------------------------------------- //
		Fetch!(0xa0, Register.AL, FieldType.Mem8, Opcode.Mov) ~
		Fetch!(0xa1, Register.CL, FieldType.Mem, Opcode.Mov) ~
		Fetch!(0xa2, FieldType.Mem8, Register.AL, Opcode.Mov) ~
		Fetch!(0xa3, FieldType.Mem, Register.RAX, Opcode.Mov) ~
		Fetch!(0xa4, Register.DI, Register.SI, Opcode.Movs) ~
		Fetch!(0xa5, Register.RDI, Register.RSI, Opcode.Movs) ~
		Fetch!(0xa6, Register.SI, Register.DI, Opcode.Cmps) ~
		Fetch!(0xa7, Register.RSI, Register.RDI, Opcode.Cmps) ~
		// --------------------------------------------------- //
		Fetch!(0xa8, Register.AL, FieldType.Imm8, Opcode.Test) ~
		Fetch!(0xa9, Register.RAX, FieldType.Immz, Opcode.Test) ~
		Fetch!(0xaa, Register.DI, Register.AL, Opcode.Stos) ~
		Fetch!(0xab, Register.RDI, Register.RAX, Opcode.Stos) ~
		Fetch!(0xac, Register.AL, Register.SI, Opcode.Lods) ~
		Fetch!(0xad, Register.RAX, Register.RSI, Opcode.Lods) ~
		Fetch!(0xae, Register.AL, Register.DI, Opcode.Scas) ~
		Fetch!(0xaf, Register.RAX, Register.RDI, Opcode.Scas) ~
		// --------------------------------------------------- //
		Fetch!(0xb0, Register.AL, FieldType.Imm8, Opcode.Mov) ~
		Fetch!(0xb1, Register.CL, FieldType.Imm8, Opcode.Mov) ~
		Fetch!(0xb2, Register.DL, FieldType.Imm8, Opcode.Mov) ~
		Fetch!(0xb3, Register.BL, FieldType.Imm8, Opcode.Mov) ~
		Fetch!(0xb4, Register.AH, FieldType.Imm8, Opcode.Mov) ~
		Fetch!(0xb5, Register.CH, FieldType.Imm8, Opcode.Mov) ~
		Fetch!(0xb6, Register.DH, FieldType.Imm8, Opcode.Mov) ~
		Fetch!(0xb7, Register.BH, FieldType.Imm8, Opcode.Mov) ~
		// --------------------------------------------------- //
		Fetch!(0xb8, Register.RAX, FieldType.Imm, Opcode.Mov) ~
		Fetch!(0xb9, Register.RCX, FieldType.Imm, Opcode.Mov) ~
		Fetch!(0xba, Register.RDX, FieldType.Imm, Opcode.Mov) ~
		Fetch!(0xbb, Register.RBX, FieldType.Imm, Opcode.Mov) ~
		Fetch!(0xbc, Register.RSP, FieldType.Imm, Opcode.Mov) ~
		Fetch!(0xbd, Register.RBP, FieldType.Imm, Opcode.Mov) ~
		Fetch!(0xbe, Register.RSI, FieldType.Imm, Opcode.Mov) ~
		Fetch!(0xbf, Register.RDI, FieldType.Imm, Opcode.Mov) ~
		// --------------------------------------------------- //
		Fetch!(0xc0, FieldType.Rm8, FieldType.Imm8, Opcode.Rol, Opcode.Ror, Opcode.Rcl, Opcode.Rcr, Opcode.Shl, Opcode.Shr, Opcode.Sal, Opcode.Sar) ~
		Fetch!(0xc1, FieldType.Rm, FieldType.Imm8, Opcode.Rol, Opcode.Ror, Opcode.Rcl, Opcode.Rcr, Opcode.Shl, Opcode.Shr, Opcode.Sal, Opcode.Sar) ~
		Fetch!(0xc2, FieldType.None, FieldType.Imm16, Opcode.Ret) ~
		Fetch!(0xc3, FieldType.None, FieldType.None, Opcode.Ret) ~
		Fetch!(0xc4, FieldType.Regz, FieldType.Mem, Opcode.Les) ~
		Fetch!(0xc5, FieldType.Regz, FieldType.Mem, Opcode.Lds) ~
		Fetch!(0xc6, FieldType.Rm8, FieldType.Imm8, Opcode.Mov, Opcode.Null, Opcode.Null, Opcode.Null, Opcode.Null, Opcode.Null, Opcode.Null, Opcode.Null) ~
		Fetch!(0xc7, FieldType.Rm, FieldType.Immz, Opcode.Mov, Opcode.Null, Opcode.Null, Opcode.Null, Opcode.Null, Opcode.Null, Opcode.Null, Opcode.Null) ~
		// --------------------------------------------------- //
		Fetch3!(0xc8, FieldType.None, FieldType.Imm16, FieldType.Imm8, Opcode.Enter) ~
		Fetch!(0xc9, FieldType.None, FieldType.Imm, Opcode.Leave) ~
		Fetch!(0xca, FieldType.None, FieldType.Imm16, Opcode.Ret) ~
		Fetch!(0xcb, FieldType.None, FieldType.None, Opcode.Ret) ~
		Fetch!(0xcc, FieldType.None, FieldType.None, Opcode.Int3) ~
		Fetch!(0xcd, FieldType.None, FieldType.Imm8, Opcode.Int) ~
		Fetch!(0xce, FieldType.None, FieldType.None, Opcode.Into) ~
		Fetch!(0xcf, FieldType.None, FieldType.None, Opcode.Iret) ~
		// --------------------------------------------------- //
		Fetch!(0xd0, FieldType.Rm8, FieldType.One, Opcode.Rol, Opcode.Ror, Opcode.Rcl, Opcode.Rcr, Opcode.Shl, Opcode.Shr, Opcode.Sal, Opcode.Sar) ~
		Fetch!(0xd1, FieldType.Rm, FieldType.One, Opcode.Rol, Opcode.Ror, Opcode.Rcl, Opcode.Rcr, Opcode.Shl, Opcode.Shr, Opcode.Sal, Opcode.Sar) ~
		Fetch!(0xd2, FieldType.Rm8, Register.CL, Opcode.Rol, Opcode.Ror, Opcode.Rcl, Opcode.Rcr, Opcode.Shl, Opcode.Shr, Opcode.Sal, Opcode.Sar) ~
		Fetch!(0xd3, FieldType.Rm, Register.CL, Opcode.Rol, Opcode.Ror, Opcode.Rcl, Opcode.Rcr, Opcode.Shl, Opcode.Shr, Opcode.Sal, Opcode.Sar) ~
		Fetch!(0xd4, FieldType.None, FieldType.None, Opcode.Aam) ~
		Fetch!(0xd5, FieldType.None, FieldType.None, Opcode.Aad) ~
		Fetch!(0xd6, FieldType.None, FieldType.None, Opcode.Salc) ~
		Fetch!(0xd7, FieldType.None, FieldType.None, Opcode.Xlat) ~
		// --------------------------------------------------- //

		// x87 codes //

		// --------------------------------------------------- //
		Fetch!(0xe0, FieldType.None, FieldType.Imm8, Opcode.Loopne) ~
		Fetch!(0xe1, FieldType.None, FieldType.Imm8, Opcode.Loope) ~
		Fetch!(0xe2, FieldType.None, FieldType.Imm8, Opcode.Loop) ~
		Fetch!(0xe3, FieldType.None, FieldType.Imm8, Opcode.Jcxz) ~
		Fetch!(0xe4, Register.AL, FieldType.Imm8, Opcode.In) ~
		Fetch!(0xe5, Register.EAX, FieldType.Imm8, Opcode.In) ~
		Fetch!(0xe6, Register.AL, FieldType.Imm8, Opcode.Out) ~
		Fetch!(0xe7, Register.EAX, FieldType.Imm8, Opcode.Out) ~
		// --------------------------------------------------- //
		Fetch!(0xe8, FieldType.None, FieldType.Immz, Opcode.Call) ~
		Fetch!(0xe9, FieldType.None, FieldType.Immz, Opcode.Jmp) ~
		Fetch!(0xea, FieldType.FarPtr, FieldType.None, Opcode.Jmp) ~	// Far Jmp
		Fetch!(0xeb, FieldType.None, FieldType.Imm8, Opcode.Jmp) ~
		Fetch!(0xec, Register.AL, Register.DX, Opcode.In) ~
		Fetch!(0xed, Register.EAX, Register.DX, Opcode.In) ~
		Fetch!(0xee, Register.DX, Register.AL, Opcode.Out) ~
		Fetch!(0xef, Register.DX, Register.EAX, Opcode.Out) ~
		// --------------------------------------------------- //
		PreFix!(0xf0, Prefix.Lock) ~
		Fetch!(0xf1, FieldType.None, FieldType.One, Opcode.Int) ~
		PreFix!(0xf2, Prefix.Repne) ~
		PreFix!(0xf3, Prefix.Rep) ~ // XXX: Repe???
		Fetch!(0xf4, FieldType.None, FieldType.None, Opcode.Hlt) ~
		Fetch!(0xf5, FieldType.None, FieldType.None, Opcode.Cmc) ~
		// Fetch Special : the first two opcodes selected by modrm.reg get the source
		// 		in this case: Imm8 or Immz
		//		the rest get FieldType.None (do not grab an immediate value)
		FetchMod!(0xf6, FieldType.Rm8, FieldType.Imm8, Opcode.Test,
						FieldType.Rm8, FieldType.Imm8, Opcode.Test,
						FieldType.Rm8, FieldType.None, Opcode.Not,
						FieldType.Rm8, FieldType.None, Opcode.Neg,
						FieldType.Rm8, Register.AL, Opcode.Mul,
						FieldType.Rm8, FieldType.None, Opcode.Imul,
						Register.AL, FieldType.Rm8, Opcode.Div,		// destination: specifies quotient result register
						FieldType.Rm8, FieldType.None, Opcode.Idiv) ~
		FetchMod!(0xf7, FieldType.Rm, FieldType.Immz, Opcode.Test,
						FieldType.Rm, FieldType.Immz, Opcode.Test,
						FieldType.Rm, FieldType.None, Opcode.Not,
						FieldType.Rm, FieldType.None, Opcode.Neg,
						FieldType.Rm, Register.RAX, Opcode.Mul,
						FieldType.Rm, FieldType.None, Opcode.Imul,	// Far Jmp
						Register.RAX, FieldType.Rm, Opcode.Div,
						FieldType.Rm, FieldType.None, Opcode.Idiv) ~
		// --------------------------------------------------- //
		Fetch!(0xf8, FieldType.None, FieldType.None, Opcode.Clc) ~
		Fetch!(0xf9, FieldType.None, FieldType.None, Opcode.Stc) ~
		Fetch!(0xfa, FieldType.None, FieldType.None, Opcode.Cli) ~
		Fetch!(0xfb, FieldType.None, FieldType.None, Opcode.Sti) ~
		Fetch!(0xfc, FieldType.None, FieldType.None, Opcode.Cld) ~
		Fetch!(0xfd, FieldType.None, FieldType.None, Opcode.Std) ~
		Fetch!(0xfe, FieldType.Rm8, FieldType.None, Opcode.Inc, Opcode.Dec, Opcode.Null,Opcode.Null,Opcode.Null,Opcode.Null,Opcode.Null,Opcode.Null) ~
		FetchMod!(0xff, FieldType.Rm, FieldType.None, Opcode.Inc,
							FieldType.Rm, FieldType.None, Opcode.Dec,
							FieldType.None, FieldType.Rm, Opcode.Call,
							FieldType.Mem, FieldType.None, Opcode.Call,
							FieldType.None, FieldType.Rm, Opcode.Jmp,
							FieldType.Mem, FieldType.None, Opcode.Jmp,	// Far Jmp
							FieldType.None, FieldType.Rm, Opcode.Push,
							FieldType.None, FieldType.None, Opcode.Null) ~





	`

	default:
		op = Opcode.Null;
		accSrc = Access.Null;
		accDst = Access.Null;
		accThree = Access.Null;

	}`;
}

template PreFix(ubyte opcode, Prefix pfix)
{
	const char[] PreFix = `

		case ` ~ Itoh!(opcode) ~ `: prefix |= cast(Prefix)` ~ Itoa!(pfix) ~ `;` ~

		`
			goto _decodestart;

	`;
}

template Fetch(ubyte opcode, ushort dst, ushort src, Ops...)
{
	const char[] Fetch = `

		case ` ~ Itoh!(opcode) ~ `:` ~

		grabModRM!(src,dst,Ops) ~
		grabOp!(Ops) ~
		getDisp!(src,dst) ~
		getDestination!(dst) ~
		getSource!(src) ~
		getThree!(FieldType.None) ~

		 `


			break;

	`;
}

template FetchMod(ubyte opcode, ushort dst0, ushort src0, ushort op0,
								ushort dst1, ushort src1, ushort op1,
								ushort dst2, ushort src2, ushort op2,
								ushort dst3, ushort src3, ushort op3,
								ushort dst4, ushort src4, ushort op4,
								ushort dst5, ushort src5, ushort op5,
								ushort dst6, ushort src6, ushort op6,
								ushort dst7, ushort src7, ushort op7)
{
	const char[] FetchMod = `

		case ` ~ Itoh!(opcode) ~ `:` ~

			grabModRM!(dst0, src0, op0, op1, op2, op3, op4, op5, op6, op7) ~
			grabOp!(op0, op1, op2, op3, op4, op5, op6, op7) ~
			`
			switch(modrm.reg)
			{
				case 0: ` ~

					getDisp!(src0, dst0) ~
					getDestination!(dst0) ~
					getSource!(src0) ~
					getThree!(FieldType.None) ~

				` break;
				case 1: ` ~

					getDisp!(src1, dst1) ~
					getDestination!(dst1) ~
					getSource!(src1) ~
					getThree!(FieldType.None) ~

				` break;
				case 2: ` ~

					getDisp!(src2, dst2) ~
					getDestination!(dst2) ~
					getSource!(src2) ~
					getThree!(FieldType.None) ~

				` break;
				case 3: ` ~

					getDisp!(src3, dst3) ~
					getDestination!(dst3) ~
					getSource!(src3) ~
					getThree!(FieldType.None) ~

				` break;
				case 4: ` ~

					getDisp!(src4, dst4) ~
					getDestination!(dst4) ~
					getSource!(src4) ~
					getThree!(FieldType.None) ~

				` break;
				case 5: ` ~

					getDisp!(src5, dst5) ~
					getDestination!(dst5) ~
					getSource!(src5) ~
					getThree!(FieldType.None) ~

				` break;
				case 6: ` ~

					getDisp!(src6, dst6) ~
					getDestination!(dst6) ~
					getSource!(src6) ~
					getThree!(FieldType.None) ~

				` break;
				case 7: ` ~

					getDisp!(src7, dst7) ~
					getDestination!(dst7) ~
					getSource!(src7) ~
					getThree!(FieldType.None) ~

				` break;
			}

			break;

	`;
}

template FetchSpecial(ubyte opcode, ushort dst, ushort src, Ops...)
{
	const char[] FetchSpecial = `

		case ` ~ Itoh!(opcode) ~ `:` ~

		grabModRM!(src,dst,Ops) ~
		grabOp!(Ops) ~
		getDisp!(src,dst) ~
		getDestination!(dst) ~
		` if (modrm.reg < 2) { ` ~
			getSource!(src) ~
		` } else { ` ~
			getSource!(FieldType.None) ~
		` } ` ~
		getThree!(FieldType.None) ~

		 `


			break;

	`;
}

template Fetch3(ubyte opcode, ushort dst, ushort src, ushort imm, Ops...)
{
	const char[] Fetch3 = `

		case ` ~ Itoh!(opcode) ~ `:` ~

		grabModRM!(src,dst,Ops) ~
		grabOp!(Ops) ~
		getDisp!(src,dst) ~
		getDestination!(dst) ~
		getSource!(src) ~
		getThree!(imm) ~

		 `


			break;

	`;
}

template getDisp(ushort dst, ushort src)
{
	static if (dst == FieldType.Rm || dst == FieldType.Rm8 || dst == FieldType.Rm16 || dst == FieldType.Rm32 ||
				src == FieldType.Rm || src == FieldType.Rm8 || src == FieldType.Rm16 || src == FieldType.Rm32 ||
				dst == FieldType.Mem || src == FieldType.Mem)
	{
		const char[] getDisp = `
		if (modrm.mod == 1)
		{
			popDisp8(disp);
		}
		else if (modrm.mod == 2)
		{
			popDisp16(disp);
		}`;
	}
	else
	{
		const char[] getDisp = ``;
	}
}

template grabOp(Ops...)
{
	static if (Ops.length == 1)
	{
		const char[] grabOp = `op = ` ~ Itoh!(Ops[0]) ~ `;`;
	}
	else static if (Ops.length == 8)
	{
		const char[] grabOp = `switch(modrm.reg) { ` ~
			`case 0: op = ` ~ Itoh!(Ops[0]) ~ `; break;` ~
			`case 1: op = ` ~ Itoh!(Ops[1]) ~ `; break;` ~
			`case 2: op = ` ~ Itoh!(Ops[2]) ~ `; break;` ~
			`case 3: op = ` ~ Itoh!(Ops[3]) ~ `; break;` ~
			`case 4: op = ` ~ Itoh!(Ops[4]) ~ `; break;` ~
			`case 5: op = ` ~ Itoh!(Ops[5]) ~ `; break;` ~
			`case 6: op = ` ~ Itoh!(Ops[6]) ~ `; break;` ~
			`case 7: op = ` ~ Itoh!(Ops[7]) ~ `; break;` ~

			` } `;
	}
	else
	{
		static assert(false, "Wrong number of Opcodes given, There needs to be 8. Fill in Opcode.Null when necessary.");
	}
}

template grabOpField(Ops...)
{
}

// will, if necessary, get the ModRM byte
template grabModRM(ushort src, ushort dst, Ops...)
{
	static if (src == FieldType.Reg || src == FieldType.Rm || src == FieldType.Mem ||
				dst == FieldType.Reg || dst == FieldType.Rm || dst == FieldType.Mem ||
				src == FieldType.Rm8 || src == FieldType.Rm16 || src == FieldType.Rm32 ||
				dst == FieldType.Rm8 || dst == FieldType.Rm16 || dst == FieldType.Rm32 ||
				src == FieldType.Segment || dst == FieldType.Segment ||
				Ops.length > 1)
	{
		const char[] grabModRM = `if (!popModRM(modrm)) { return false; }`;
	}
	else
	{
		const char[] grabModRM = ``;
	}
}

template getDestination(ushort dst)
{
	static if (dst < Register.max)
	{
		const char[] getDestination = `accDst = Access.Reg; regDst = ` ~ Itoa!(dst) ~ `;`;
	}
	else static if (dst == FieldType.Reg)
	{
		const char[] getDestination = `
			if (mode == Mode.Real)
			{
				regDst = cast(ulong)(baseReg[1] + modrm.reg);
			}
			else if (mode == Mode.Protected)
			{
				regDst = cast(ulong)(baseReg[2] + modrm.reg);
			}
			else
			{
				// look at prefix
				assert(false, "long mode Reg not implemented");
			}
			accDst = Access.Reg;`;
	}
	else static if (dst == FieldType.Rm)
	{
		const char[] getDestination = `
			//writefln("RM : ", modrm.rm);
			if (modrm.mod == 3)
			{
				if (mode == Mode.Real)
				{
					regDst = cast(ulong)(baseReg[1] + modrm.rm);
				}
				else if (mode == Mode.Protected)
				{
					regDst = cast(ulong)(baseReg[2] + modrm.rm);
				}
				else
				{
					// look at prefix
					assert(false, "long mode Reg not implemented");
				}

				accDst = Access.Reg;
			}
			else
			{
				if (mode == Mode.Real)
				{
					if (modrm.rm == 0) { regDst = cast(ulong)(Register.BX); accDst = Access.OffsetSI; }
					else if (modrm.rm == 1) { regDst = cast(ulong)(Register.BX); accDst = Access.OffsetDI; }
					else if (modrm.rm == 2) { regDst = cast(ulong)(Register.BP); accDst = Access.OffsetSI; }
					else if (modrm.rm == 3) { regDst = cast(ulong)(Register.BP); accDst = Access.OffsetDI; }
					else if (modrm.rm == 4) { regDst = cast(ulong)(Register.SI); accDst = Access.Offset; }
					else if (modrm.rm == 5) { regDst = cast(ulong)(Register.DI); accDst = Access.Offset; }
					else if (modrm.rm == 6 && modrm.mod != 0) { regDst = cast(ulong)(Register.BP); accDst = Access.Offset; }
					else if (modrm.rm == 6) { /* ... disp16 ... */ accDst = Access.Offset0; }
					else { regDst = cast(ulong)(Register.BX); accDst = Access.Offset; }

					if (modrm.mod == 0 && modrm.rm != 6)
					{
						accDst = Access.Addr;
					}
				}
				else if (mode == Mode.Protected)
				{
					regDst = cast(ulong)(baseReg[2] + modrm.rm);
				}
				else
				{
					// look at prefix
					assert(false, "long mode Reg not implemented");
				}
			}
			`;
	}
	else static if (dst == FieldType.Regz)
	{
		const char[] getDestination = `
			if (mode == Mode.Real)
			{
				regDst = cast(ulong)(baseReg[1] + modrm.reg);
			}
			else
			{
				regDst = cast(ulong)(baseReg[2] + modrm.reg);
			}
			accDst = Access.Reg;
			`;
	}
	else static if (dst == FieldType.Rm8 || dst == FieldType.Rm16 || dst == FieldType.Rm32)
	{
		const char[] getDestination = `
			//writefln("RM : ", modrm.rm);
			if (modrm.mod == 3)
			{
				if (mode == Mode.Real)
				{
					regDst = cast(ulong)(baseReg[` ~ Itoa!(dst - FieldType.Rm8) ~ `] + modrm.rm);
				}
				else if (mode == Mode.Protected)
				{
					regDst = cast(ulong)(baseReg[2] + modrm.rm);
				}
				else
				{
					// look at prefix
					assert(false, "long mode Reg not implemented");
				}

				accDst = Access.Reg;
			}
			else
			{

				if (mode == Mode.Real)
				{
					if (modrm.rm == 0) { regDst = cast(ulong)(Register.BX); accDst = Access.OffsetSI; }
					else if (modrm.rm == 1) { regDst = cast(ulong)(Register.BX); accDst = Access.OffsetDI; }
					else if (modrm.rm == 2) { regDst = cast(ulong)(Register.BP); accDst = Access.OffsetSI; }
					else if (modrm.rm == 3) { regDst = cast(ulong)(Register.BP); accDst = Access.OffsetDI; }
					else if (modrm.rm == 4) { regDst = cast(ulong)(Register.SI); accDst = Access.Offset; }
					else if (modrm.rm == 5) { regDst = cast(ulong)(Register.DI); accDst = Access.Offset; }
					else if (modrm.rm == 6 && modrm.mod != 0) { regDst = cast(ulong)(Register.BP); accDst = Access.Offset; }
					else if (modrm.rm == 6) { /* ... disp16 ... */ accDst = Access.Offset0; }
					else { regDst = cast(ulong)(Register.BX); accDst = Access.Offset; }

					if (modrm.mod == 0 && modrm.rm != 6)
					{
						accDst = Access.Addr;
					}
				}
				else if (mode == Mode.Protected)
				{
					regDst = cast(ulong)(baseReg[2] + modrm.rm);
				}
				else
				{
					// look at prefix
					assert(false, "long mode Reg not implemented");
				}
			}
			`;
	}
	else static if (dst == FieldType.Segment)
	{
		const char[] getDestination = `
			if (modrm.rm > 5) { op = Opcode.Null; }
			regDst = cast(ulong)(Register.ES + modrm.reg);
			accDst = Access.Reg;
		`;
	}
	else static if (dst == FieldType.Reg8 || dst == FieldType.Reg16 || dst == FieldType.Reg32)
	{
		const char[] getDestination = `
			regDst = cast(ulong)(baseReg[` ~ Itoa!(dst - FieldType.Reg8) ~ `] + modrm.reg);
			accDst = Access.Reg;
		`;
	}
	else static if (dst == FieldType.Mem16Rm)
	{
		const char[] getDestination = `
			if (modrm.mod == 3)
			{
				// rm is register
				if (mode == Mode.Real)
				{
					regDst = cast(ulong)(baseReg[1] + modrm.rm);
				}
				else if (mode == Mode.Protected)
				{
					regDst = cast(ulong)(baseReg[2] + modrm.rm);
				}
				else
				{
					assert(false, "long mode Reg not implemented");
				}
				accDst = Access.Reg;
			}
			else
			{
				// like the Mem field
				if (mode == Mode.Real)
				{
					if (!popImm8(regDst)) { return false; }
				}
				else if (mode == Mode.Protected)
				{
					if (!popImm16(regDst)) { return false; }
				}
				else
				{
					// long
					if (!popImm32(regDst)) { return false; }
				}
				accDst = Access.Mem;
			}
		`;
	}
	else static if (dst == FieldType.Mem)
	{
		const char[] getDestination = ``;
	}
	else static if (dst == FieldType.Mem8)
	{
		const char[] getDestination = `
			if (!popImm8(regDst)) { return false; }
			accDst = Access.Mem;
		`;
	}
	else static if (dst == FieldType.Mem16)
	{
		const char[] getDestination = `
			if (!popImm16(regDst)) { return false; }
			accDst = Access.Mem;
		`;
	}
	else static if (dst == FieldType.Mem32)
	{
		const char[] getDestination = `
			if (!popImm32(regDst)) { return false; }
			accDst = Access.Mem;
		`;
	}
	else static if (dst == FieldType.Mem64)
	{
		const char[] getDestination = `
			if (!popImm64(regDst)) { return false; }
			accDst = Access.Mem;
		`;
	}
	else static if (dst == FieldType.None)
	{
		const char[] getDestination = `
			accDst = Access.Null;
		`;
	}
	else static if (dst == FieldType.One)
	{
		const char[] getDestination = `
			accDst = Access.Imm8;
			regDst = 1;
		`;
	}
	else static if (dst == FieldType.FarPtr)
	{
		const char[] getDestination = `
			if (mode == Mode.Real) {
				if (!popImm16(regDst)) { return false; }
				accDst = Access.Imm16;
			}
			else if (mode == Mode.Protected) {
				if (!popImm32(regDst)) { return false; }
				accDst = Access.Imm32;
			}
		`;
	}
	else		// INVALID (immediates)
	{
		static assert(false, "Destination is marked as Immediate");
	}
}

template getSource(ushort src)
{
	static if (src < Register.max)
	{
		const char[] getSource = `accSrc = Access.Reg; regSrc = ` ~ Itoa!(src) ~ `;`;
	}
	else static if (src == FieldType.Reg)
	{
		const char[] getSource = `
			if (mode == Mode.Real)
			{
				regSrc = cast(ulong)(baseReg[1] + modrm.reg);
			}
			else if (mode == Mode.Protected)
			{
				regSrc = cast(ulong)(baseReg[2] + modrm.reg);
			}
			else
			{
				assert(false, "long mode Reg not implemented");
			}
			accSrc = Access.Reg;`;
	}
	else static if (src == FieldType.Rm)
	{
		const char[] getSource = `
			//writefln("RM-- : ", modrm.rm, " MOD: ", modrm.mod, " REG: ", modrm.reg);
			if (modrm.mod == 3)
			{
				if (mode == Mode.Real)
				{
					regSrc = cast(ulong)(baseReg[1] + modrm.rm);
				}
				else if (mode == Mode.Protected)
				{
					regSrc = cast(ulong)(baseReg[2] + modrm.rm);
				}
				else
				{
					assert(false, "long mode Reg not implemented");
				}
				accSrc = Access.Reg;
			}
			else
			{
				if (mode == Mode.Real)
				{
					if (modrm.rm == 0) { regSrc = cast(ulong)(Register.BX); accSrc = Access.OffsetSI; }
					else if (modrm.rm == 1) { regSrc = cast(ulong)(Register.BX); accSrc = Access.OffsetDI; }
					else if (modrm.rm == 2) { regSrc = cast(ulong)(Register.BP); accSrc = Access.OffsetSI; }
					else if (modrm.rm == 3) { regSrc = cast(ulong)(Register.BP); accSrc = Access.OffsetDI; }
					else if (modrm.rm == 4) { regSrc = cast(ulong)(Register.SI); accSrc = Access.Offset; }
					else if (modrm.rm == 5) { regSrc = cast(ulong)(Register.DI); accSrc = Access.Offset; }
					else if (modrm.rm == 6 && modrm.mod != 0) { regSrc = cast(ulong)(Register.BP); accSrc = Access.Offset; }
					else if (modrm.rm == 6) { /* ... disp16 ... */ accSrc = Access.Offset0; }
					else { regSrc = cast(ulong)(Register.BX); accSrc = Access.Offset; }

					if (modrm.mod == 0 && modrm.rm != 6)
					{
						accSrc = Access.Addr;
					}
				}
				else if (mode == Mode.Protected)
				{
					regSrc = cast(ulong)(baseReg[2] + modrm.rm);
				}
				else
				{
					// look at prefix
					assert(false, "long mode Reg not implemented");
				}
			}

			`;
	}
	else static if (src == FieldType.Regz)
	{
		const char[] getSource = `
			if (mode == Mode.Real)
			{
				regSrc = cast(ulong)(baseReg[1] + modrm.reg);
			}
			else
			{
				regSrc = cast(ulong)(baseReg[2] + modrm.reg);
			}
			accSrc = Access.Reg;
		`;
	}
	else static if (src == FieldType.Rmz)
	{
		const char[] getSource = `
			//writefln("RM-- : ", modrm.rm, " MOD: ", modrm.mod, " REG: ", modrm.reg);
			if (modrm.mod == 3)
			{
				if (mode == Mode.Real)
				{
					regSrc = cast(ulong)(baseReg[1] + modrm.rm);
				}
				else
				{
					regSrc = cast(ulong)(baseReg[2] + modrm.rm);
				}
				accSrc = Access.Reg;
			}
			else
			{
				if (mode == Mode.Real)
				{
					if (modrm.rm == 0) { regSrc = cast(ulong)(Register.BX); accSrc = Access.OffsetSI; }
					else if (modrm.rm == 1) { regSrc = cast(ulong)(Register.BX); accSrc = Access.OffsetDI; }
					else if (modrm.rm == 2) { regSrc = cast(ulong)(Register.BP); accSrc = Access.OffsetSI; }
					else if (modrm.rm == 3) { regSrc = cast(ulong)(Register.BP); accSrc = Access.OffsetDI; }
					else if (modrm.rm == 4) { regSrc = cast(ulong)(Register.SI); accSrc = Access.Offset; }
					else if (modrm.rm == 5) { regSrc = cast(ulong)(Register.DI); accSrc = Access.Offset; }
					else if (modrm.rm == 6 && modrm.mod != 0) { regSrc = cast(ulong)(Register.BP); accSrc = Access.Offset; }
					else if (modrm.rm == 6) { /* ... disp16 ... */ accSrc = Access.Offset0; }
					else { regSrc = cast(ulong)(Register.BX); accSrc = Access.Offset; }

					if (modrm.mod == 0 && modrm.rm != 6)
					{
						accSrc = Access.Addr;
					}
				}
				else if (mode == Mode.Protected)
				{
					regSrc = cast(ulong)(baseReg[2] + modrm.rm);
				}
				else
				{
					// look at prefix
					assert(false, "long mode Reg not implemented");
				}
			}

			`;
	}
	else static if (src == FieldType.Rm8 || src == FieldType.Rm16 || src == FieldType.Rm32)
	{
		const char[] getSource = `
			//writefln("RM-- : ", modrm.rm, " MOD: ", modrm.mod, " REG: ", modrm.reg);
			//operandSize = ` ~ Itoa!((src - FieldType.Rm8) * 8) ~ `;
			if (modrm.mod == 3)
			{
				regSrc = cast(ulong)(baseReg[` ~ Itoa!(src - FieldType.Rm8) ~ `] + modrm.rm);
				accSrc = Access.Reg;
			}
			else
			{
				if (mode == Mode.Real)
				{
					if (modrm.rm == 0) { regSrc = cast(ulong)(Register.BX); accSrc = Access.OffsetSI; }
					else if (modrm.rm == 1) { regSrc = cast(ulong)(Register.BX); accSrc = Access.OffsetDI; }
					else if (modrm.rm == 2) { regSrc = cast(ulong)(Register.BP); accSrc = Access.OffsetSI; }
					else if (modrm.rm == 3) { regSrc = cast(ulong)(Register.BP); accSrc = Access.OffsetDI; }
					else if (modrm.rm == 4) { regSrc = cast(ulong)(Register.SI); accSrc = Access.Offset; }
					else if (modrm.rm == 5) { regSrc = cast(ulong)(Register.DI); accSrc = Access.Offset; }
					else if (modrm.rm == 6 && modrm.mod != 0) { regSrc = cast(ulong)(Register.BP); accSrc = Access.Offset; }
					else if (modrm.rm == 6) { /* ... disp16 ... */ accSrc = Access.Offset0; }
					else { regSrc = cast(ulong)(Register.BX); accSrc = Access.Offset; }

					if (modrm.mod == 0 && modrm.rm != 6)
					{
						accSrc = Access.Addr;
					}
				}
				else if (mode == Mode.Protected)
				{
					regSrc = cast(ulong)(baseReg[2] + modrm.rm);
				}
				else
				{
					// look at prefix
					assert(false, "long mode Reg not implemented");
				}
			}

		`;
	}
	else static if (src == FieldType.Segment)
	{
		const char[] getSource = `
			if (modrm.rm > 5) { op = Opcode.Null; }
			regSrc = cast(ulong)(Register.ES + modrm.reg);
			accSrc = Access.Reg;
		`;
	}
	else static if (src == FieldType.Reg8 || src == FieldType.Reg16 || src == FieldType.Reg32)
	{
		const char[] getSource = `
			regSrc = cast(ulong)(baseReg[` ~ Itoa!(src - FieldType.Reg8) ~ `] + modrm.reg);
			accSrc = Access.Reg;
		`;
	}
	else static if (src == FieldType.Imm)
	{
		const char[] getSource = `
			if (mode == Mode.Real)
			{
				if (!popImm16(regSrc)) { return false; }
				accSrc = Access.Imm16;
			}
			else if (mode == Mode.Protected)
			{
				if (!popImm32(regSrc)) { return false; }
				accSrc = Access.Imm32;
			}
			else if (mode == Mode.Long)
			{
				if (!popImm64(regSrc)) { return false; }
				accSrc = Access.Imm64;
			}
		`;
	}
	else static if (src == FieldType.Immz)
	{
		const char[] getSource = `
			if (mode == Mode.Real)
			{
				if (!popImm16(regSrc)) { return false; }
				accSrc = Access.Imm16;
			}
			else
			{
				if (!popImm32(regSrc)) { return false; }
				accSrc = Access.Imm32;
			}
		`;
	}
	else static if (src == FieldType.Imm8)
	{
		const char[] getSource = `
			if (!popImm8(regSrc)) { return false; }
			accSrc = Access.Imm8;
		`;
	}
	else static if (src == FieldType.Imm16)
	{
		const char[] getSource = `
			if (!popImm16(regSrc)) { return false; }
			accSrc = Access.Imm16;
		`;
	}
	else static if (src == FieldType.Imm32)
	{
		const char[] getSource = `
			if (!popImm32(regSrc)) { return false; }
			accSrc = Access.Imm32;
		`;
	}
	else static if (src == FieldType.Imm64)
	{
		const char[] getSource = `
			if (!popImm64(regSrc)) { return false; }
			accSrc = Access.Imm64;
		`;
	}
	else static if (src == FieldType.Mem16Rm)
	{
		const char[] getSource = `
			if (modrm.mod == 3)
			{
				// rm is register
				if (mode == Mode.Real)
				{
					regSrc = cast(ulong)(baseReg[1] + modrm.rm);
				}
				else if (mode == Mode.Protected)
				{
					regSrc = cast(ulong)(baseReg[2] + modrm.rm);
				}
				else
				{
					assert(false, "long mode Reg not implemented");
				}
				accSrc = Access.Reg;
			}
			else
			{
				// like the Mem field
				if (mode == Mode.Real)
				{
					if (!popImm8(regSrc)) { return false; }
				}
				else if (mode == Mode.Protected)
				{
					if (!popImm16(regSrc)) { return false; }
				}
				else
				{
					// long
					if (!popImm32(regSrc)) { return false; }
				}
				accSrc = Access.Mem;
			}
		`;
	}
	else static if (src == FieldType.Mem)
	{
		const char[] getSource = `
			//writefln("RM-- : ", modrm.rm, " MOD: ", modrm.mod, " REG: ", modrm.reg);
			if (modrm.mod == 3)
			{
				// Invalid?
				op = Opcode.Null;
				accDst = Access.Null;
			}
			else
			{
				if (mode == Mode.Real)
				{
					if (modrm.rm == 0) { regSrc = cast(ulong)(Register.BX); accSrc = Access.OffsetSI; }
					else if (modrm.rm == 1) { regSrc = cast(ulong)(Register.BX); accSrc = Access.OffsetDI; }
					else if (modrm.rm == 2) { regSrc = cast(ulong)(Register.BP); accSrc = Access.OffsetSI; }
					else if (modrm.rm == 3) { regSrc = cast(ulong)(Register.BP); accSrc = Access.OffsetDI; }
					else if (modrm.rm == 4) { regSrc = cast(ulong)(Register.SI); accSrc = Access.Offset; }
					else if (modrm.rm == 5) { regSrc = cast(ulong)(Register.DI); accSrc = Access.Offset; }
					else if (modrm.rm == 6 && modrm.mod != 0) { regSrc = cast(ulong)(Register.BP); accSrc = Access.Offset; }
					else if (modrm.rm == 6) { /* ... disp16 ... */ accSrc = Access.Offset0; }
					else { regSrc = cast(ulong)(Register.BX); accSrc = Access.Offset; }

					if (modrm.mod == 0 && modrm.rm != 6)
					{
						accSrc = Access.Addr;
					}
				}
				else if (mode == Mode.Protected)
				{
					regSrc = cast(ulong)(baseReg[2] + modrm.rm);
				}
				else
				{
					// look at prefix
					assert(false, "long mode Mem (src) not implemented");
				}
			}
		`;
	}
	else static if (src == FieldType.Mem8)
	{
		const char[] getSource = `
			if (!popImm8(regSrc)) { return false; }
			accSrc = Access.Mem;
		`;
	}
	else static if (src == FieldType.Mem16)
	{
		const char[] getSource = `
			if (!popImm16(regSrc)) { return false; }
			accSrc = Access.Mem;
		`;
	}
	else static if (src == FieldType.Mem32)
	{
		const char[] getSource = `
			if (!popImm32(regSrc)) { return false; }
			accSrc = Access.Mem;
		`;
	}
	else static if (src == FieldType.Mem64)
	{
		const char[] getSource = `
			if (!popImm64(regSrc)) { return false; }
			accSrc = Access.Mem;
		`;
	}
	else static if (src == FieldType.One)
	{
		const char[] getSource = `
			accSrc = Access.Imm8;
			regSrc = 1;
		`;
	}
	else static if (src == FieldType.FarPtr)
	{
		const char[] getSource = `
			if (mode == Mode.Real) {
				if (!popImm16(regSrc)) { return false; }
				accSrc = Access.Imm16;
			}
			else if (mode == Mode.Protected) {
				if (!popImm32(regSrc)) { return false; }
				accSrc = Access.Imm32;
			}
		`;
	}
	else static if (src == FieldType.None)
	{
		const char[] getSource = `
			accSrc = Access.Null;
		`;
	}
	else
	{
		static assert(false, "getSource: unimplemented condition");
	}
}

template getThree(ushort src)
{
	static if (src < Register.max)
	{
		const char[] getThree = `accThree = Access.Reg; regThree = ` ~ Itoa!(src) ~ `;`;
	}
	else static if (src == FieldType.Reg)
	{
		const char[] getThree = ``;
	}
	else static if (src == FieldType.Rm)
	{
		const char[] getThree = ``;
	}
	else static if (src == FieldType.Rm8 || src == FieldType.Rm16 || src == FieldType.Rm32)
	{
		const char[] getThree = `
			regThree = cast(ulong)(baseReg[` ~ Itoa!(src - FieldType.Rm8) ~ `] + modrm.rm);

			// access is defined by the mod field
			switch(modrm.mod)
			{
				case 0: // register is address
					accThree = Access.Addr;
					break;
				case 1: // register is address + byte displacement
					accThree = Access.Offset;
					break;
				case 2: // register is address + word displacement
					accThree = Access.Offset;
					break;
				case 3: // register is register
					accThree = Access.Reg;
					break;
			}
		`;
	}
	else static if (src == FieldType.Reg8 || src == FieldType.Reg16 || src == FieldType.Reg32)
	{
		const char[] getThree = `
			regThree = cast(ulong)(baseReg[` ~ Itoa!(src - FieldType.Reg8) ~ `] + modrm.reg);
			accThree = Access.Reg;
		`;
	}
	else static if (src == FieldType.Imm8)
	{
		const char[] getThree = `
			if (!popImm8(regThree)) { return false; }
			accThree = Access.Imm8;
		`;
	}
	else static if (src == FieldType.Imm16)
	{
		const char[] getThree = `
			if (!popImm16(regThree)) { return false; }
			accThree = Access.Imm16;
		`;
	}
	else static if (src == FieldType.Imm32)
	{
		const char[] getThree = `
			if (!popImm32(regThree)) { return false; }
			accThree = Access.Imm32;
		`;
	}
	else static if (src == FieldType.Imm64)
	{
		const char[] getThree = `
			if (!popImm64(regThree)) { return false; }
			accThree = Access.Imm64;
		`;
	}
	else static if (src == FieldType.Mem)
	{
		const char[] getThree = `
		`;
	}
	else static if (src == FieldType.Mem8)
	{
		const char[] getThree = `
			if (!popImm8(regThree)) { return false; }
			accThree = Access.Mem;
		`;
	}
	else static if (src == FieldType.Mem16)
	{
		const char[] getThree = `
			if (!popImm16(regThree)) { return false; }
			accThree = Access.Mem;
		`;
	}
	else static if (src == FieldType.Mem32)
	{
		const char[] getThree = `
			if (!popImm32(regThree)) { return false; }
			accThree = Access.Mem;
		`;
	}
	else static if (src == FieldType.Mem64)
	{
		const char[] getThree = `
			if (!popImm64(regThree)) { return false; }
			accThree = Access.Mem;
		`;
	}
	else static if (src == FieldType.One)
	{
		const char[] getThree = `
			accThree = Access.Imm;
			regThree = 1;
		`;
	}
	else
	{
		const char[] getThree = `
			accThree = Access.Null;
		`;
	}
}

enum Mode:ushort
{
	Real,
	Protected,
	Long,
}

bool decode1632(ref ushort op, ref Mode mode, ref Access accSrc, ref ulong regSrc, ref Access accDst, ref ulong regDst, ref Access accThree, ref ulong regThree, ref Prefix prefix, ref long disp) //, ref ulong operandSize)
{
	ubyte opcode;
	ModRM modrm;
	prefix = Prefix.None;
//	operandSize = (cast(ushort)mode+1) * 8;

_decodestart:

	if(!popCode(opcode)) { return false; }

	mixin(Fetch1632!());

	return true;
}
