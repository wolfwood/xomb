module user.xombemu.x86emu;

import std.stdio;

import user.xombemu.x86.opcodes;
import user.xombemu.x86.registers;
import user.xombemu.x86.fetch;
import user.xombemu.x86.stack;
import user.xombemu.x86.memory;
import user.xombemu.x86.interrupt;

import user.util;

char[] readln()
{
	return "c\n";
}

// used for checking the least-sign byte for even number of 1s
// denotes the value of the flag when the flag is modifiable.
bool parityCheck[256] = [
1,0,0,1,0,1,1,0,0,1,1,0,1,0,0,1,0,1,1,0,1,0,0,1,1,0,0,1,0,1,1,0,0,1,1,0,1,0,0,1,
1,0,0,1,0,1,1,0,1,0,0,1,0,1,1,0,0,1,1,0,1,0,0,1,0,1,1,0,1,0,0,1,1,0,0,1,0,1,1,0,
1,0,0,1,0,1,1,0,0,1,1,0,1,0,0,1,1,0,0,1,0,1,1,0,0,1,1,0,1,0,0,1,0,1,1,0,1,0,0,1,
1,0,0,1,0,1,1,0,0,1,1,0,1,0,0,1,1,0,0,1,0,1,1,0,1,0,0,1,0,1,1,0,0,1,1,0,1,0,0,1,
1,0,0,1,0,1,1,0,0,1,1,0,1,0,0,1,0,1,1,0,1,0,0,1,1,0,0,1,0,1,1,0,1,0,0,1,0,1,1,0,
0,1,1,0,1,0,0,1,0,1,1,0,1,0,0,1,1,0,0,1,0,1,1,0,0,1,1,0,1,0,0,1,1,0,0,1,0,1,1,0,
1,0,0,1,0,1,1,0,0,1,1,0,1,0,0,1
];

// masks for arithmetic rotations
ulong rotateMasks16[32] = [0x0000, 0x8000, 0xC000, 0xE000, 0xF000, 0xF800, 0xFC00, 0xFE00,
						   0xFF00, 0xFF80, 0xFFC0, 0xFFE0, 0xFFF0, 0xFFF8, 0xFFFC, 0xFFFE,
						   0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF,
						   0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF];

ulong rotateMasks32[32] = [0x00000000, 0x80000000, 0xC0000000, 0xE0000000, 0xF0000000, 0xF8000000, 0xFC000000, 0xFE000000,
						   0xFF000000, 0xFF800000, 0xFFC00000, 0xFFE00000, 0xFFF00000, 0xFFF80000, 0xFFFC0000, 0xFFFE0000,
						   0xFFFF0000, 0xFFFF8000, 0xFFFFC000, 0xFFFFE000, 0xFFFFF000, 0xFFFFF800, 0xFFFFFC00, 0xFFFFFE00,
						   0xFFFFFF00, 0xFFFFFF80, 0xFFFFFFC0, 0xFFFFFFE0, 0xFFFFFFF0, 0xFFFFFFF8, 0xFFFFFFFC, 0xFFFFFFFE];

ulong rotateMasks64[64] = [0x0000000000000000UL, 0x8000000000000000UL, 0xC000000000000000UL, 0xE000000000000000UL,
						   0xF000000000000000UL, 0xF800000000000000UL, 0xFC00000000000000UL, 0xFE00000000000000UL,
						   0xFF00000000000000UL, 0xFF80000000000000UL, 0xFFC0000000000000UL, 0xFFE0000000000000UL,
						   0xFFF0000000000000UL, 0xFFF8000000000000UL, 0xFFFC000000000000UL, 0xFFFE000000000000UL,
						   0xFFFF000000000000UL, 0xFFFF800000000000UL, 0xFFFFC00000000000UL, 0xFFFFE00000000000UL,
						   0xFFFFF00000000000UL, 0xFFFFF80000000000UL, 0xFFFFFC0000000000UL, 0xFFFFFE0000000000UL,
						   0xFFFFFF0000000000UL, 0xFFFFFF8000000000UL, 0xFFFFFFC000000000UL, 0xFFFFFFE000000000UL,
						   0xFFFFFFF000000000UL, 0xFFFFFFF800000000UL, 0xFFFFFFFC00000000UL, 0xFFFFFFFE00000000UL,
						   0xFFFFFFFF00000000UL, 0xFFFFFFFF80000000UL, 0xFFFFFFFFC0000000UL, 0xFFFFFFFFE0000000UL,
						   0xFFFFFFFFF0000000UL, 0xFFFFFFFFF8000000UL, 0xFFFFFFFFFC000000UL, 0xFFFFFFFFFE000000UL,
						   0xFFFFFFFFFF000000UL, 0xFFFFFFFFFF800000UL, 0xFFFFFFFFFFC00000UL, 0xFFFFFFFFFFE00000UL,
						   0xFFFFFFFFFFF00000UL, 0xFFFFFFFFFFF80000UL, 0xFFFFFFFFFFFC0000UL, 0xFFFFFFFFFFFE0000UL,
						   0xFFFFFFFFFFFF0000UL, 0xFFFFFFFFFFFF8000UL, 0xFFFFFFFFFFFFC000UL, 0xFFFFFFFFFFFFE000UL,
						   0xFFFFFFFFFFFFF000UL, 0xFFFFFFFFFFFFF800UL, 0xFFFFFFFFFFFFFC00UL, 0xFFFFFFFFFFFFFE00UL,
						   0xFFFFFFFFFFFFFF00UL, 0xFFFFFFFFFFFFFF80UL, 0xFFFFFFFFFFFFFFC0UL, 0xFFFFFFFFFFFFFFE0UL,
						   0xFFFFFFFFFFFFFFF0UL, 0xFFFFFFFFFFFFFFF8UL, 0xFFFFFFFFFFFFFFFCUL, 0xFFFFFFFFFFFFFFFEUL];

// masks for finding the new carry bit in a rotation
ulong rotateCarryBit16[32] = [0x0000, 0x8000, 0x4000, 0x2000, 0x1000, 0x0800, 0x0400, 0x0200,
							  0x0100, 0x0080, 0x0040, 0x0020, 0x0010, 0x0008, 0x0004, 0x0002,
							  0x0001, 0x0000, 0x8000, 0x4000, 0x2000, 0x1000, 0x0800, 0x0400,
							  0x0200, 0x0100, 0x0080, 0x0040, 0x0020, 0x0010, 0x0008, 0x0004];

ulong rotateCarryBit32[32] = [0x00000000, 0x80000000, 0x40000000, 0x20000000, 0x10000000, 0x08000000, 0x04000000, 0x02000000,
							  0x01000000, 0x00800000, 0x00400000, 0x00200000, 0x00100000, 0x00080000, 0x00040000, 0x00020000,
							  0x00010000, 0x00008000, 0x00004000, 0x00002000, 0x00001000, 0x00000800, 0x00000400, 0x00000200,
							  0x00000100, 0x00000080, 0x00000040, 0x00000020, 0x00000010, 0x00000008, 0x00000004, 0x00000002];

ulong rotateCarryBit64[64] = [0x0000000000000000UL, 0x8000000000000000UL, 0x4000000000000000UL, 0x2000000000000000UL,
							  0x1000000000000000UL, 0x0800000000000000UL, 0x0400000000000000UL, 0x0200000000000000UL,
							  0x0100000000000000UL, 0x0080000000000000UL, 0x0040000000000000UL, 0x0020000000000000UL,
							  0x0010000000000000UL, 0x0008000000000000UL, 0x0004000000000000UL, 0x0002000000000000UL,
							  0x0001000000000000UL, 0x0000800000000000UL, 0x0000400000000000UL, 0x0000200000000000UL,
							  0x0000100000000000UL, 0x0000080000000000UL, 0x0000040000000000UL, 0x0000020000000000UL,
							  0x0000010000000000UL, 0x0000008000000000UL, 0x0000004000000000UL, 0x0000002000000000UL,
							  0x0000001000000000UL, 0x0000000800000000UL, 0x0000000400000000UL, 0x0000000200000000UL,
							  0x0000000100000000UL, 0x0000000080000000UL, 0x0000000040000000UL, 0x0000000020000000UL,
							  0x0000000010000000UL, 0x0000000008000000UL, 0x0000000004000000UL, 0x0000000002000000UL,
							  0x0000000001000000UL, 0x0000000000800000UL, 0x0000000000400000UL, 0x0000000000200000UL,
							  0x0000000000100000UL, 0x0000000000080000UL, 0x0000000000040000UL, 0x0000000000020000UL,
							  0x0000000000010000UL, 0x0000000000008000UL, 0x0000000000004000UL, 0x0000000000002000UL,
							  0x0000000000001000UL, 0x0000000000000800UL, 0x0000000000000400UL, 0x0000000000000200UL,
							  0x0000000000000100UL, 0x0000000000000080UL, 0x0000000000000040UL, 0x0000000000000020UL,
							  0x0000000000000010UL, 0x0000000000000008UL, 0x0000000000000004UL, 0x0000000000000002UL];

// masks for getting, for a rotation, the high bits that will be pushed to the right side (rotate carry left)
ulong rotateCarryLeft16[32] = [0x0000, 0x0000, 0x8000, 0xC000, 0xE000, 0xF000, 0xF800, 0xFC00,
							   0xFE00, 0xFF00, 0xFF80, 0xFFC0, 0xFFE0, 0xFFF0, 0xFFF8, 0xFFFC,
							   0xFFFE, 0x0000, 0x0000, 0x8000, 0xC000, 0xE000, 0xF000, 0xF800,
							   0xFC00, 0xFE00, 0xFF00, 0xFF80, 0xFFC0, 0xFFE0, 0xFFF0, 0xFFF8];

							   // Left Shift Amounts to Normalize Before Or'ing Final Value
							 // 0,		16,		15,		14,		13,		12,		11,		10,    16 - ((index+16) % 17)
							 // 9,		8,		7,		6,		5,		4,		3,		2,
							 // 1,		0,		16,		15,		14,		13,		12,		11,
							 // 10,		9,		8,		7,		6,		5,		4,		3,

ulong rotateCarryLeft32[32] = [0x00000000, 0x00000000, 0x80000000, 0xC0000000, 0xE0000000, 0xF0000000, 0xF8000000, 0xFC000000,
							   0xFE000000, 0xFF000000, 0xFF800000, 0xFFC00000, 0xFFE00000, 0xFFF00000, 0xFFF80000, 0xFFFC0000,
							   0xFFFE0000, 0xFFFF0000, 0xFFFF8000, 0xFFFFC000, 0xFFFFE000, 0xFFFFF000, 0xFFFFF800, 0xFFFFFC00,
							   0xFFFFFE00, 0xFFFFFF00, 0xFFFFFF80, 0xFFFFFFC0, 0xFFFFFFE0, 0xFFFFFFF0, 0xFFFFFFF8, 0xFFFFFFFC];

							 // formula: 32 - ((index+32) % 33)

							 // 0,			32,			31,			30,			29,			28,			27,			26,
							 // 25,			24,			23,			22,			21,			20,			19,			18,
							 // 17,			16,			15,			14,			13,			12,			11,			10,
							 // 9,			8,			7,			6,			5,			4,			3,			2

ulong rotateCarryLeft64[64] = [0x0000000000000000UL, 0x0000000000000000UL, 0x8000000000000000UL, 0xC000000000000000UL,
							   0xE000000000000000UL, 0xF000000000000000UL, 0xF800000000000000UL, 0xFC00000000000000UL,
							   0xFE00000000000000UL, 0xFF00000000000000UL, 0xFF80000000000000UL, 0xFFC0000000000000UL,
							   0xFFE0000000000000UL, 0xFFF0000000000000UL, 0xFFF8000000000000UL, 0xFFFC000000000000UL,
							   0xFFFE000000000000UL, 0xFFFF000000000000UL, 0xFFFF800000000000UL, 0xFFFFC00000000000UL,
							   0xFFFFE00000000000UL, 0xFFFFF00000000000UL, 0xFFFFF80000000000UL, 0xFFFFFC0000000000UL,
							   0xFFFFFE0000000000UL, 0xFFFFFF0000000000UL, 0xFFFFFF8000000000UL, 0xFFFFFFC000000000UL,
							   0xFFFFFFE000000000UL, 0xFFFFFFF000000000UL, 0xFFFFFFF800000000UL, 0xFFFFFFFC00000000UL,
							   0xFFFFFFFE00000000UL, 0xFFFFFFFF00000000UL, 0xFFFFFFFF80000000UL, 0xFFFFFFFFC0000000UL,
							   0xFFFFFFFFE0000000UL, 0xFFFFFFFFF0000000UL, 0xFFFFFFFFF8000000UL, 0xFFFFFFFFFC000000UL,
							   0xFFFFFFFFFE000000UL, 0xFFFFFFFFFF000000UL, 0xFFFFFFFFFF800000UL, 0xFFFFFFFFFFC00000UL,
							   0xFFFFFFFFFFE00000UL, 0xFFFFFFFFFFF00000UL, 0xFFFFFFFFFFF80000UL, 0xFFFFFFFFFFFC0000UL,
							   0xFFFFFFFFFFFE0000UL, 0xFFFFFFFFFFFF0000UL, 0xFFFFFFFFFFFF8000UL, 0xFFFFFFFFFFFFC000UL,
							   0xFFFFFFFFFFFFE000UL, 0xFFFFFFFFFFFFF000UL, 0xFFFFFFFFFFFFF800UL, 0xFFFFFFFFFFFFFC00UL,
							   0xFFFFFFFFFFFFFE00UL, 0xFFFFFFFFFFFFFF00UL, 0xFFFFFFFFFFFFFF80UL, 0xFFFFFFFFFFFFFFC0UL,
							   0xFFFFFFFFFFFFFFE0UL, 0xFFFFFFFFFFFFFFF0UL, 0xFFFFFFFFFFFFFFF8UL, 0xFFFFFFFFFFFFFFFCUL];

						     // formula: 64 - ((index+64) % 65)


// print human friendly disassembly of the last decoded instruction
void printInstruction(ushort op, Access accSrc, ulong src, Access accDst, ulong dst, ulong disp)
{
	writef("%s", opcodeNames[op]);

	if (accSrc == Access.Reg)
	{
		writef(" %s", registerNames[src]);
	}
	else if (accSrc == Access.Addr)
	{
		writef(" (%s)", registerNames[src]);
	}
	else if (accSrc == Access.Offset)
	{
		writef(" ", cast(long)disp, "(", registerNames[src], ")");
	}
	else if (accSrc == Access.Imm8)
	{
		writef(" $0x%.2x", src);
	}
	else if (accSrc == Access.Imm16)
	{
		writef(", $0x%.4x", src);
	}
	else if (accSrc == Access.Imm32)
	{
		writef(", $0x%.8x", src);
	}
	else if (accSrc == Access.Imm64)
	{
		writef(", $0x%.16x", src);
	}

	if (accDst == Access.Reg)
	{
		writef(", ", registerNames[dst]);
	}
	else if (accDst == Access.Addr)
	{
		writef(", (", registerNames[dst], ")");
	}
	else if (accDst == Access.Offset)
	{
		writef(", ", cast(long)disp, "(", registerNames[dst], ")");
	}
	else if (accDst == Access.Imm8)
	{
		writef(", $0x%.2x", dst);
	}
	else if (accDst == Access.Imm8)
	{
		writef(", $0x%.2x", dst);
	}
	else if (accDst == Access.Imm16)
	{
		writef(", $0x%.4x", dst);
	}
	else if (accDst == Access.Imm32)
	{
		writef(", $0x%.8x", dst);
	}
	else if (accDst == Access.Imm64)
	{
		writef(", $0x%.16x", dst);
	}
}

//import user.syscall;

void clearRegisters()
{
	idtr.i64 = 0;

	foreach(reg; registers)
	{
		reg.i64 = 0;
	}
}

void init()
{
	writef("\n");
	writef("XOmBemu - XOmB x86 emulation layer\n");
	writef("version 1.0\n");
	writef("\n");
	writef("p - print stack\n");
	writef("s - step\n");
	writef("n - step over call\n");
	writef("c - continue\n");
	writef("q - quit\n");
	writef("\n");

	clearRegisters();
}

void mapRam(void* addr)
{
	Memory.init(cast(ulong)addr);
}

void mapStack(ulong newss, ulong addr)
{
	ss.i64 = newss;
	rsp.i64 = addr;
}

void fireInterrupt(ulong vector)
{
	Interrupt.fire(vector);

	execute();
}

int execute()
{
	ushort op;

	ulong src;
	ulong dst;
	ulong three;
	Access accSrc;
	Access accDst;
	Access accThree;
	Prefix pfix;

	Mode mode;

	mode = Mode.Real;

	long aluSrc;
	long aluDst;
	long aluThree;

	long disp;		// displacement

	ulong aluSrcU;
	ulong aluDstU;
	ulong aluThreeU;

	ulong effectiveAddress;

	bool contMode = false;
	bool skipCall = false;
	bool skipLine = false;
	int nestedCallCount = 0;

	ulong old_rip = rip.i64;
	ulong old_trans = Memory.translateRip();

	char[] lastLine = "s\n";
	char[] line;

	while(decode1632(op, mode, accSrc, src, accDst, dst, accThree, three, pfix, disp))
	{
		if (accSrc == Access.Reg || accSrc == Access.Offset)
		{
			if (src < Register.R8)
			{
				if (mode == Mode.Real)
				{
					if (src >= Register.RAX)
					{
						// 64 bit register
						src -= 16;
					}
					else if (src >= Register.EAX)
					{
						// 32 bit register
						src -= 8;
					}
				}
				else if (mode == Mode.Protected)
				{
					if (src >= Register.RAX)
					{
						// 64 bit... truncate to 32 bit
						src -= 8;
					}
				}
				else // long mode
				{
					// check prefix to reach registers R8+
					// all registers are go
				}
			}
		}

		if (accDst == Access.Reg || accDst == Access.Offset)
		{
			if (dst < Register.R8)
			{
				if (mode == Mode.Real)
				{
					if (dst >= Register.RAX)
					{
						// 64 bit register
						dst -= 16;
					}
					else if (dst >= Register.EAX)
					{
						// 32 bit register
						dst -= 8;
					}
				}
				else if (mode == Mode.Protected)
				{
					if (dst >= Register.RAX)
					{
						// 64 bit... truncate to 32 bit
						dst -= 8;
					}
				}
				else // long mode
				{
					// check prefix to reach registers R8+
					// all registers are go
				}
			}
		}
/*

		if (mode == Mode.Real)
		{
			writef(cs.i64, ":", old_rip, " | ");
		}
		else if (mode == Mode.Protected)
		{
			writef("%.4x:%.8x", cs.i64, old_rip, " | ");
		}
		else
		{
			writef("%.4x:%.16x", cs.i64, old_rip, " | ");
		}

		printInstruction(op,accSrc,src,accDst,dst,disp);

		writef("\n");

		ulong curRip = Memory.translateRip();
		//foreach(databyte; Memory.ram[old_trans..curRip])
		//{/
		//	writef("%x",databyte);
		//}

		//writef("]\n"); //*/
readLine:
		if (!contMode && !skipLine) {

			skipCall = false;

			//writef("> ");
			line = readln();

interpLine:
			switch(line[0..$-1])
			{
				case "c":
					contMode = true;
					goto cont;
					break;
				case "s":
					goto cont;
					break;
				case "n":
					skipCall = true;
					nestedCallCount = 0;
					goto cont;
					break;
				case "p":
					// print stack
					Stack.print(8);
					break;
				case "r":
					// print registers
					printAll();
					break;
				case "q":
					return 0;
					break;
				default:
					line = lastLine;
					goto interpLine;
					break;
			}

			lastLine = line;
			goto readLine;
		}

cont:
		lastLine = line;
		switch(op)
		{
			case Opcode.Null:
				return 0;
				break;






				// Stack Ops

			case Opcode.Push:

				mixin(getAluSrcU!());

				if (mode == Mode.Real)
				{
					Stack.pushW(aluSrcU);
				}
				else if (mode == Mode.Protected)
				{
					Stack.pushD(aluSrcU);
				}
				else
				{
					Stack.pushQ(aluSrcU);
				}

				break;

			case Opcode.Pop:

				if (mode == Mode.Real)
				{
					aluDst = Stack.popW();
				}
				else if (mode == Mode.Protected)
				{
					aluDst = Stack.popD();
				}
				else
				{
					aluDst = Stack.popQ();
				}

				mixin(setAluDst!());

				break;

			case Opcode.PushA:
				long old_rsp = rsp.i64;

				if (mode == Mode.Real)
				{
					Stack.pushW(rax.i64);
					Stack.pushW(rcx.i64);
					Stack.pushW(rdx.i64);
					Stack.pushW(rbx.i64);
					Stack.pushW(old_rsp);
					Stack.pushW(rbp.i64);
					Stack.pushW(rsi.i64);
					Stack.pushW(rdi.i64);
				}
				else if (mode == Mode.Protected)
				{
					Stack.pushD(rax.i64);
					Stack.pushD(rcx.i64);
					Stack.pushD(rdx.i64);
					Stack.pushD(rbx.i64);
					Stack.pushD(old_rsp);
					Stack.pushD(rbp.i64);
					Stack.pushD(rsi.i64);
					Stack.pushD(rdi.i64);
				}
				else
				{
					Stack.pushQ(rax.i64);
					Stack.pushQ(rcx.i64);
					Stack.pushQ(rdx.i64);
					Stack.pushQ(rbx.i64);
					Stack.pushQ(old_rsp);
					Stack.pushQ(rbp.i64);
					Stack.pushQ(rsi.i64);
					Stack.pushQ(rdi.i64);
				}

				break;

			case Opcode.PopA:
				long new_rsp;

				if (mode == Mode.Real)
				{
					rdi.i64 = Stack.popW();
					rsi.i64 = Stack.popW();
					rbp.i64 = Stack.popW();
					new_rsp = Stack.popW();
					rbx.i64 = Stack.popW();
					rdx.i64 = Stack.popW();
					rcx.i64 = Stack.popW();
					rax.i64 = Stack.popW();
				}
				else if (mode == Mode.Protected)
				{
					rdi.i64 = Stack.popD();
					rsi.i64 = Stack.popD();
					rbp.i64 = Stack.popD();
					new_rsp = Stack.popD();
					rbx.i64 = Stack.popD();
					rdx.i64 = Stack.popD();
					rcx.i64 = Stack.popD();
					rax.i64 = Stack.popD();
				}
				else
				{
					rdi.i64 = Stack.popQ();
					rsi.i64 = Stack.popQ();
					rbp.i64 = Stack.popQ();
					new_rsp = Stack.popQ();
					rbx.i64 = Stack.popQ();
					rdx.i64 = Stack.popQ();
					rcx.i64 = Stack.popQ();
					rax.i64 = Stack.popQ();
				}

				rsp.i64 = new_rsp;

				break;

			case Opcode.PushF:

				if (mode == Mode.Real)
				{
					Stack.pushW(rflags.i64);
				}
				else if (mode == Mode.Protected)
				{
					Stack.pushD(rflags.i64);
				}
				else
				{
					Stack.pushQ(rflags.i64);
				}

				break;

			case Opcode.PopF:

				if (mode == Mode.Real)
				{
					rflags.i64 = Stack.popW();
				}
				else if (mode == Mode.Protected)
				{
					rflags.i64 = Stack.popD();
				}
				else
				{
					rflags.i64 = Stack.popQ();
				}

				break;






				// Increment, Decrement

				// INC
				// Increment
			case Opcode.Inc:

				mixin(getAluDst!());

				// set aux carry
				if (mode == Mode.Real)
				{
					//writef("aluDst: %x", aluDst, " + %x", 1, " = %x", (cast(ulong)aluDst) + (cast(ulong)1));
					if ((cast(ulong)(aluDst & 0xff)) + 1 > 0xff)
					{
						rflags.aux = 1;
					}
					else
					{
						rflags.aux = 0;
					}
				}
				else if (mode == Mode.Protected)
				{
				}
				else // long
				{
				}

				aluDst ++;

				// zero
				if (aluDst == 0) { rflags.zero = 1; } else { rflags.zero = 0; }

				// parity
				rflags.parity = parityCheck[(cast(ubyte*)&aluDst)[0]];

				// overflow, sign
				if (mode == Mode.Real)
				{
					if (aluDst & 0x8000)
					{
						rflags.sign = 1;
						if ((aluDst & 0xffff) == 0x8000) // 0x7fff + 1 == 0x8000
						{
							rflags.overflow = 1;
						}
						else
						{
							rflags.overflow = 0;
						}
					}
					else
					{
						rflags.sign = 0;
						if ((aluDst & 0xffff) == 0x0) // 0xffff + 1 == 0x0
						{
							rflags.overflow = 1;
						}
						else
						{
							rflags.overflow = 0;
						}
					}
				}
				else if (mode == Mode.Protected)
				{
				}
				else // long
				{

				}

				//w/ritefln("result: 0x%x", aluDst, " ... p: ", rflags.parity, " a: ",  rflags.aux, " z: ", rflags.zero, " s: ", rflags.sign, " o: ", rflags.overflow);

				mixin(setAluDst!());

				break;

				// DEC
				// Decrement (signed, unsigned)
			case Opcode.Dec:

				mixin(getAluDst!());

				// set pre-sign and carry
				if (mode == Mode.Real)
				{
					//writef("aluDst: %x", aluDst, " - %x", 1, " = %x", (cast(ulong)aluDst) - (cast(ulong)1));
					if ((cast(ulong)(aluDst & 0xff)) - 1 > 0xff)
					{
						rflags.aux = 1;
					}
					else
					{
						rflags.aux = 0;
					}
				}
				else if (mode == Mode.Protected)
				{
				}
				else // long
				{
				}

				aluDst --;

				// zero
				if (aluDst == 0) { rflags.zero = 1; } else { rflags.zero = 0; }

				// parity
				rflags.parity = parityCheck[(cast(ubyte*)&aluDst)[0]];

				// overflow, sign
				if (mode == Mode.Real)
				{
					if (aluDst & 0x8000)
					{
						rflags.sign = 1;
						if ((aluDst & 0xffff) == 0xffff) // 0x0 - 1 == 0xffff
						{
							rflags.overflow = 1;
						}
						else
						{
							rflags.overflow = 0;
						}
					}
					else
					{
						rflags.sign = 0;
						if ((aluDst & 0xffff) == 0x7fff)	// 0x8000 - 0x1 == 0x7fff
						{
							rflags.overflow = 1;
						}
						else
						{
							rflags.overflow = 0;
						}
					}
				}
				else if (mode == Mode.Protected)
				{
				}
				else // long
				{

				}

				//writef("result: ", aluDst, " ... p: ", rflags.parity, " c: ", rflags.carry, " z: ", rflags.zero, " s: ", rflags.sign, " o: ", rflags.overflow);

				mixin(setAluDst!());

				break;







				// Moves and Loads

			case Opcode.Mov:

				mixin(getAluSrcU!());

				aluDstU = aluSrcU;

				mixin(setAluDstU!());

				break;

			case Opcode.Lea:

				mixin(getAluSrcU!());

				aluDstU = effectiveAddress;

				mixin(setAluDstU!());

				break;





				// Port Ops

			case Opcode.Out:

				mixin(getAluSrcU!());
				mixin(getAluDstU!());

				if (src == Register.AL)
				{
					asm{
						"movq %0, %%rax" :: "m" aluSrcU : "rax";
						"movq %0, %%rdx" :: "m" aluDstU : "rdx";
						"out %%al, %%dx";
					}
				}
				else if (src == Register.AX)
				{
					asm{
						"movq %0, %%rax" :: "m" aluSrcU : "rax";
						"movq %0, %%rdx" :: "m" aluDstU : "rdx";
						"out %%ax, %%dx";
					}
				}
				else if (src == Register.EAX)
				{
					asm{
						"movq %0, %%rax" :: "m" aluSrcU : "rax";
						"movq %0, %%rdx" :: "m" aluDstU : "rdx";
						"out %%eax, %%dx";
					}
				}

//				writef("OUT : port: (", aluDstU, ") val: ", aluSrcU, "\n");
				break;

			case Opcode.In:

				mixin(getAluSrcU!());
				mixin(getAluDstU!());

				if(dst==Register.AL)
				{
					asm {
						"movq %0, %%rdx" :: "m" aluSrcU : "rdx";
						"movq $0, %%rax";
						"in %%dx, %%al";
						"movq %%rax, %0" :: "m" aluDstU : "rax";
					}
				}
				else if (dst==Register.AX)
				{
					asm {
						"movq %0, %%rdx" :: "m" aluSrcU : "rdx";
						"movq $0, %%rax";
						"in %%dx, %%ax";
						"movq %%rax, %0" :: "m" aluDstU : "rax";
					}
				}
				else
				{
					asm {
						"movq %0, %%rdx" :: "m" aluSrcU : "rdx";
						"movq $0, %%rax";
						"in %%dx, %%eax";
						"movq %%rax, %0" :: "m" aluDstU : "rax";
					}
				}

//				writef("IN : port: (", aluSrcU, ") 0x%x", aluSrcU);
				mixin(setAluDstU!());
				break;














				// Rotate Ops

				// RCL
				// Rotate Through Carry Left

			case Opcode.Rcl:

				// Shift the destination the amount specified by the source register

				mixin(getAluSrcU!()); // count
				mixin(getAluDstU!());

				bool new_carry = false;
				ulong carry_bits = 0;

				if (mode == Mode.Real)
				{
					aluSrcU &= 0x1F;	// mask to only let values from 0 - 31 (lower 5 bits)

					if (aluSrcU != 0)
					{
						// get new carry
						new_carry = (aluDstU & rotateCarryBit16[aluSrcU]) > 0;

						// get bits that will be rotated onto the right side
						carry_bits = (aluDstU & rotateCarryLeft16[aluSrcU]);

						// shift right carry_bits before we can or it
						carry_bits >>= 16 - ((aluSrcU+16) % 17); // formula explained at definition of rotateCarryLeft16[]

						// perform a shift to shift in carry
						if (rflags.carry)
						{
							aluDstU <<= 1;
							aluDstU |= 1;

							// shift rest of the amount
							aluDstU <<= aluSrcU - 1;
						}
						else
						{
							// just shift in 0's all the way
							aluDstU <<= aluSrcU;
						}

						// or in rest of value
						aluDstU |= carry_bits;
					}
					else
					{
						break;
					}
				}
				else if (mode == Mode.Protected)
				{
					aluSrcU &= 0x1F;	// mask to only let values from 0 - 31 (lower 5 bits)

					if (aluSrcU != 0)
					{
						// get new carry
						new_carry = (aluDstU & rotateCarryBit32[aluSrcU]) > 0;

						// get bits that will be rotated onto the right side
						carry_bits = (aluDstU & rotateCarryLeft32[aluSrcU]);

						// shift right carry_bits before we can or it
						carry_bits >>= 32 - ((aluSrcU+32) % 33); // formula explained at definition of rotateCarryLeft32[]

						// perform a shift to shift in carry
						if (rflags.carry)
						{
							aluDstU <<= 1;
							aluDstU |= 1;

							// shift rest of the amount
							aluDstU <<= aluSrcU - 1;
						}
						else
						{
							// just shift in 0's all the way
							aluDstU <<= aluSrcU;
						}

						// or in rest of value
						aluDstU |= carry_bits;
					}
					else
					{
						break;
					}
				}
				else
				{
					aluSrcU &= 0x3F;	// mask to only let values from 0 - 63 (lower 6 bits)

					if (aluSrcU != 0)
					{
						// get new carry
						new_carry = (aluDstU & rotateCarryBit64[aluSrcU]) > 0;

						// get bits that will be rotated onto the right side
						carry_bits = (aluDstU & rotateCarryLeft64[aluSrcU]);

						// shift right carry_bits before we can or it
						carry_bits >>= 64 - ((aluSrcU+64) % 65); // formula explained at definition of rotateCarryLeft64[]

						// perform a shift to shift in carry
						if (rflags.carry)
						{
							aluDstU <<= 1;
							aluDstU |= 1;

							// shift rest of the amount
							aluDstU <<= aluSrcU - 1;
						}
						else
						{
							// just shift in 0's all the way
							aluDstU <<= aluSrcU;
						}

						// or in rest of value
						aluDstU |= carry_bits;
					}
					else
					{
						break;
					}
				}

				// set carry
				rflags.carry = new_carry;

				// set overflow, sign
				// XOR of carry and most-significant bit
				if (mode == Mode.Real)
				{
					if (aluDstU & 0x8000)
					{
						rflags.overflow = rflags.carry ^ 1;
					}
					else
					{
						rflags.overflow = rflags.carry ^ 0;
					}
				}
				else if (mode == Mode.Protected)
				{
					if (aluDstU & 0x80000000)
					{
						rflags.overflow = rflags.carry ^ 1;
					}
					else
					{
						rflags.overflow = rflags.carry ^ 0;
					}
				}
				else
				{
					if (aluDstU & 0x8000000000000000UL)
					{
						rflags.overflow = rflags.carry ^ 1;
					}
					else
					{
						rflags.overflow = rflags.carry ^ 0;
					}
				}

				mixin(setAluDstU!());

				break;











				// Shift Ops

				// SHL / SAL
				// Shift Left / Shift Arithmetic Left
			case Opcode.Sal:
			case Opcode.Shl:

				// Shift the destination the amount specified by the source register

				mixin(getAluSrcU!());
				mixin(getAluDstU!());

				bool last = false;
				if (mode == Mode.Real)
				{
					aluSrcU &= 0x1F;	// mask to only let values from 0 - 31 (lower 5 bits)

					if (aluSrcU != 0)
					{
						// perform a shift (0's get shifted in)
						aluDstU <<= aluSrcU-1;

						if (aluDstU & 0x8000)
						{
							last = true;
						}

						aluDstU <<= 1;
					}
				}
				else if (mode == Mode.Protected)
				{
					aluSrcU &= 0x1F;	// mask to only let values from 0 - 31 (lower 5 bits)

					if (aluSrcU != 0)
					{
						// perform a shift (0's get shifted in)
						aluDstU <<= aluSrcU-1;

						if (aluDstU & 0x80000000)
						{
							last = true;
						}

						aluDstU <<= 1;
					}
				}
				else
				{
					aluSrcU &= 0x3F;	// mask to only let values from 0 - 63 (lower 6 bits)

					if (aluSrcU != 0)
					{
						// perform a shift (0's get shifted in)
						aluDstU <<= aluSrcU-1;

						if (aluDstU & 0x8000000000000000UL)
						{
							last = true;
						}

						aluDstU <<= 1;
					}
				}

				// set carry
				rflags.carry = last;

				if (aluDstU == 0) { rflags.zero = 1; } else { rflags.zero = 0; }

				// set overflow, sign
				// XOR of carry and most-significant bit
				if (mode == Mode.Real)
				{
					if (aluDstU & 0x8000)
					{
						rflags.overflow = rflags.carry ^ 1;
						rflags.sign = 1;
					}
					else
					{
						rflags.overflow = rflags.carry ^ 0;
						rflags.sign = 0;
					}
				}
				else if (mode == Mode.Protected)
				{
					if (aluDstU & 0x80000000)
					{
						rflags.overflow = rflags.carry ^ 1;
						rflags.sign = 1;
					}
					else
					{
						rflags.overflow = rflags.carry ^ 0;
						rflags.sign = 0;
					}
				}
				else
				{
					if (aluDstU & 0x8000000000000000UL)
					{
						rflags.overflow = rflags.carry ^ 1;
						rflags.sign = 1;
					}
					else
					{
						rflags.overflow = rflags.carry ^ 0;
						rflags.sign = 0;
					}
				}

				// set parity
				rflags.parity = parityCheck[(cast(ubyte*)&aluDstU)[0]];

				mixin(setAluDstU!());

				break;

				// SAR
				// Shift Arithmetic Right
			case Opcode.Sar:

				// Shift the destination the amount specified by the source register
				// Shift in the sign bit

				mixin(getAluSrcU!());
				mixin(getAluDstU!());

				bool last = false;
				bool sign = false;
				if (mode == Mode.Real)
				{
					aluSrcU &= 0x1F;	// mask to only let values from 0 - 31 (lower 5 bits)

					if (aluSrcU != 0)
					{
						// perform a shift (sign get shifted in)
						if (aluDstU & 0x8000)
						{
							sign = true;
						}

						aluDstU >>= aluSrcU-1;

						if (aluDstU & 0x1)
						{
							last = true;
						}

						aluDstU >>= 1;

						// or sign bits in
						if (sign)
						{
							aluDstU |= rotateMasks16[aluSrcU];
						}
					}
				}
				else if (mode == Mode.Protected)
				{
					aluSrcU &= 0x1F;	// mask to only let values from 0 - 31 (lower 5 bits)

					if (aluSrcU != 0)
					{
						// perform a shift (sign get shifted in)
						if (aluDstU & 0x80000000)
						{
							sign = true;
						}

						aluDstU >>= aluSrcU-1;

						if (aluDstU & 0x1)
						{
							last = true;
						}

						aluDstU >>= 1;

						// or sign bits in
						if (sign)
						{
							aluDstU |= rotateMasks32[aluSrcU];
						}
					}
				}
				else
				{
					aluSrcU &= 0x3F;	// mask to only let values from 0 - 63 (lower 6 bits)

					if (aluSrcU != 0)
					{
						// perform a shift (sign get shifted in)
						if (aluDstU & 0x8000000000000000UL)
						{
							sign = true;
						}

						aluDstU >>= aluSrcU-1;

						if (aluDstU & 0x1)
						{
							last = true;
						}

						aluDstU >>= 1;

						// or sign bits in
						if (sign)
						{
							aluDstU |= rotateMasks64[aluSrcU];
						}
					}
				}

				// set carry
				rflags.carry = last;

				// set sign
				rflags.sign = sign;

				// clear overflow
				if (aluSrcU == 1)
				{
					rflags.overflow = 0;
				}

				if (aluDstU == 0) { rflags.zero = 1; } else { rflags.zero = 0; }

				// set parity
				rflags.parity = parityCheck[(cast(ubyte*)&aluDstU)[0]];

				mixin(setAluDstU!());

				break;

				// SHR
				// Shift Right
			case Opcode.Shr:

				// Shift the destination the amount specified by the source register
				// Shift in 0

				mixin(getAluSrcU!());
				mixin(getAluDstU!());

				bool last = false;
				bool sign = false;
				if (mode == Mode.Real)
				{
					aluSrcU &= 0x1F;	// mask to only let values from 0 - 31 (lower 5 bits)

					if (aluSrcU != 0)
					{
						// perform a shift (0's get shifted in)
						aluDstU >>= aluSrcU-1;

						if (aluDstU & 0x1)
						{
							last = true;
						}

						aluDstU >>= 1;
						sign = false;
					}
					else
					{
						if (aluDstU & 0x8000)
						{
							sign = true;
						}
					}
				}
				else if (mode == Mode.Protected)
				{
					aluSrcU &= 0x1F;	// mask to only let values from 0 - 31 (lower 5 bits)

					if (aluSrcU != 0)
					{
						// perform a shift (0's get shifted in)
						aluDstU >>= aluSrcU-1;

						if (aluDstU & 0x1)
						{
							last = true;
						}

						aluDstU >>= 1;
						sign = false;
					}
					else
					{
						if (aluDstU & 0x80000000)
						{
							sign = true;
						}
					}
				}
				else
				{
					aluSrcU &= 0x3F;	// mask to only let values from 0 - 63 (lower 6 bits)

					if (aluSrcU != 0)
					{
						// perform a shift (0's get shifted in)
						aluDstU >>= aluSrcU-1;

						if (aluDstU & 0x1)
						{
							last = true;
						}

						aluDstU >>= 1;
						sign = false;
					}
					else
					{
						if (aluDstU & 0x8000000000000000UL)
						{
							sign = true;
						}
					}
				}

				// set carry
				rflags.carry = last;

				// set sign
				rflags.sign = sign;

				// clear overflow
				if (aluSrcU == 1)
				{
					rflags.overflow = 0;
				}

				if (aluDstU == 0) { rflags.zero = 1; } else { rflags.zero = 0; }

				// set parity
				rflags.parity = parityCheck[(cast(ubyte*)&aluDstU)[0]];

				mixin(setAluDstU!());

				break;














				// CMP
				// Compare
			case Opcode.Cmp:

				mixin(getAluSrcU!());
				mixin(getAluDstU!());

				if (mode == Mode.Real)
				{
					if ((aluDstU - aluSrcU) & 0x8000)
					{
						rflags.sign = 1;
					}
					else
					{
						rflags.sign = 0;
					}
				}
				else if (mode == Mode.Protected)
				{
				}
				else // long
				{

				}

				rflags.parity = parityCheck[(cast(ubyte*)&aluDstU)[0]];

				if (aluDstU > aluSrcU)
				{
					rflags.carry = 0;
					rflags.zero = 0;
				}
				else if (aluDstU == aluSrcU)
				{
					rflags.carry = 0;
					rflags.zero = 1;
				}
				else
				{
					rflags.carry = 1;
					rflags.zero = 0;
				}

				aluDstU &= 0xf;
				aluSrcU &= 0xf;

				if (aluDstU > aluSrcU)
				{
					rflags.aux = 0;
				}
				else if (aluDstU == aluSrcU)
				{
					rflags.aux = 0;
				}
				else
				{
					rflags.aux = 1;
				}

				break;
			case Opcode.CmpSigned:

				mixin(getAluSrc!());
				mixin(getAluDst!());

				if (mode == Mode.Real)
				{
					if ((aluDst - aluSrc) & 0x8000)
					{
						rflags.sign = 1;
					}
					else
					{
						rflags.sign = 0;
					}
				}
				else if (mode == Mode.Protected)
				{
				}
				else // long
				{

				}

				rflags.parity = parityCheck[(cast(ubyte*)&aluDst)[0]];

				if (aluDst > aluSrc)
				{
					rflags.overflow = rflags.sign;
					rflags.zero = 0;
				}
				else if (aluDst == aluSrc)
				{
					rflags.overflow = 0;
					rflags.zero = 1;
				}
				else
				{
					rflags.overflow = !rflags.sign;
					rflags.zero = 0;
				}

				aluDstU = aluDst & 0xf;
				aluSrcU = aluSrc & 0xf;

				if (aluDstU > aluSrcU)
				{
					rflags.aux = 0;
				}
				else if (aluDstU == aluSrcU)
				{
					rflags.aux = 0;
				}
				else
				{
					rflags.aux = 1;
				}

				break;

				// NOT
				// Not
			case Opcode.Not:

				mixin(getAluDstU!());

				aluDstU = ~aluDstU;

				mixin(setAluDstU!());

				break;

				// XOR
				// Xor
			case Opcode.Xor:

				mixin(getAluSrcU!());
				mixin(getAluDstU!());

				aluDstU ^= aluSrcU;

				rflags.carry = 0;
				rflags.overflow = 0;

				if (aluDstU == 0) { rflags.zero = 1; } else { rflags.zero = 0; }

				rflags.parity = parityCheck[(cast(ubyte*)&aluDstU)[0]];

				if (mode == Mode.Real)
				{
					if (aluDstU & 0x8000)
					{
						rflags.sign = 1;
					}
					else
					{
						rflags.sign = 0;
					}
				}
				else if (mode == Mode.Protected)
				{
				}
				else // long
				{

				}

				mixin(setAluDstU!());

				break;

				// OR
				// Or
			case Opcode.Or:

				mixin(getAluSrcU!());
				mixin(getAluDstU!());

				aluDstU |= aluSrcU;

				rflags.carry = 0;
				rflags.overflow = 0;

				if (aluDstU == 0) { rflags.zero = 1; } else { rflags.zero = 0; }

				rflags.parity = parityCheck[(cast(ubyte*)&aluDstU)[0]];

				if (mode == Mode.Real)
				{
					if (aluDstU & 0x8000)
					{
						rflags.sign = 1;
					}
					else
					{
						rflags.sign = 0;
					}
				}
				else if (mode == Mode.Protected)
				{
				}
				else // long
				{

				}

				mixin(setAluDstU!());

				break;

				// TEST
				// Test (Performs And without saving result)
			case Opcode.Test:

				mixin(getAluSrcU!());
				mixin(getAluDstU!());

				aluDstU &= aluSrcU;

				rflags.carry = 0;
				rflags.overflow = 0;

				if (aluDstU == 0) { rflags.zero = 1; } else { rflags.zero = 0; }

				rflags.parity = parityCheck[(cast(ubyte*)&aluDstU)[0]];

				if (mode == Mode.Real)
				{
					if (aluDstU & 0x8000)
					{
						rflags.sign = 1;
					}
					else
					{
						rflags.sign = 0;
					}
				}
				else if (mode == Mode.Protected)
				{
				}
				else // long
				{

				}

				break;

				// AND
				// And
			case Opcode.And:

				mixin(getAluSrcU!());
				mixin(getAluDstU!());

				aluDstU &= aluSrcU;

				rflags.carry = 0;
				rflags.overflow = 0;

				if (aluDstU == 0) { rflags.zero = 1; } else { rflags.zero = 0; }

				rflags.parity = parityCheck[(cast(ubyte*)&aluDstU)[0]];

				if (mode == Mode.Real)
				{
					if (aluDstU & 0x8000)
					{
						rflags.sign = 1;
					}
					else
					{
						rflags.sign = 0;
					}
				}
				else if (mode == Mode.Protected)
				{
				}
				else // long
				{

				}

				mixin(setAluDstU!());

				break;

				// SUB
				// Sub (signed, unsigned)
			case Opcode.Sub:

				mixin(getAluSrc!());
				mixin(getAluDst!());

				bool sign;

				// set pre-sign and carry
				if (mode == Mode.Real)
				{
					sign = ((aluDst & 0x8000) != 0);
					//writef("sign: ", sign);
					//writef("aluDst: %x", aluDst, " - %x", aluSrc, " = %x", (cast(ulong)aluDst) - (cast(ulong)aluSrc));
					if ((cast(ulong)(aluDst & 0xffff)) - (cast(ulong)(aluSrc & 0xffff)) > 0xffff)
					{
						rflags.carry = 1;
					}
					else
					{
						rflags.carry = 0;
					}
				}
				else if (mode == Mode.Protected)
				{
				}
				else // long
				{
				}

				aluDst -= aluSrc;

				// zero
				if (aluDst == 0) { rflags.zero = 1; } else { rflags.zero = 0; }

				// parity
				rflags.parity = parityCheck[(cast(ubyte*)&aluDst)[0]];

				// overflow, sign
				if (mode == Mode.Real)
				{
					if (aluDst & 0x8000)
					{
						rflags.sign = 1;
						if (!sign && ((aluSrc & 0x8000) == 0))
						{
							rflags.overflow = 1;
						}
						else
						{
							rflags.overflow = 0;
						}
					}
					else
					{
						rflags.sign = 0;
						if (sign && ((aluSrc & 0x8000) != 0))
						{
							rflags.overflow = 1;
						}
						else
						{
							rflags.overflow = 0;
						}
					}
				}
				else if (mode == Mode.Protected)
				{
				}
				else // long
				{

				}

				///writef("result: ", aluDst, " ... p: ", rflags.parity, " c: ", rflags.carry, " z: ", rflags.zero, " s: ", rflags.sign, " o: ", rflags.overflow);

				mixin(setAluDst!());

				break;

				// ADD
				// Add (signed, unsigned)
			case Opcode.Add:

				mixin(getAluSrc!());
				mixin(getAluDst!());

				bool sign;

				// set pre-sign and carry
				if (mode == Mode.Real)
				{
					sign = ((aluDst & 0x8000) != 0);
					//writef("sign: ", sign);
					//writef("aluDst: %x", aluDst, " + %x", aluSrc, " = %x", (cast(ulong)aluDst) + (cast(ulong)aluSrc));
					if ((cast(ulong)(aluDst & 0xffff)) + (cast(ulong)(aluSrc & 0xffff)) > 0xffff)
					{
						rflags.carry = 1;
					}
					else
					{
						rflags.carry = 0;
					}
				}
				else if (mode == Mode.Protected)
				{
				}
				else // long
				{
				}

				aluDst += aluSrc;

				// zero
				if (aluDst == 0) { rflags.zero = 1; } else { rflags.zero = 0; }

				// parity
				rflags.parity = parityCheck[(cast(ubyte*)&aluDst)[0]];

				// overflow, sign
				if (mode == Mode.Real)
				{
					if (aluDst & 0x8000)
					{
						rflags.sign = 1;
						if (!sign && ((aluSrc & 0x8000) == 0))
						{
							rflags.overflow = 1;
						}
						else
						{
							rflags.overflow = 0;
						}
					}
					else
					{
						rflags.sign = 0;
						if (sign && ((aluSrc & 0x8000) != 0))
						{
							rflags.overflow = 1;
						}
						else
						{
							rflags.overflow = 0;
						}
					}
				}
				else if (mode == Mode.Protected)
				{
				}
				else // long
				{

				}

				//writef("result: ", aluDst, " ... p: ", rflags.parity, " c: ", rflags.carry, " z: ", rflags.zero, " s: ", rflags.sign, " o: ", rflags.overflow);

				mixin(setAluDst!());

				break;

				// MUL
				// Unsigned Multiply
			case Opcode.Mul:

				mixin(getAluDstU!());
				mixin(getAluSrcU!());

				// Multiply aluDstU by AL, AX, EAX, or RAX
				// Store result in AX, DX:AX, EDX:EAX, RDX:RAX (where the left side, or AH in the case of AX, is the high bits)

				if (src == Register.AL)
				{
					// 8 bit multiply
					// store result in AX
					ulong ret = aluDstU * aluSrcU;
					setReg(Register.RAX, ret);

					if (ret & 0xFF00)
					{
						rflags.carry = 1;
						rflags.overflow = 1;
					}
					else
					{
						rflags.carry = 0;
						rflags.overflow = 0;
					}
				}
				else
				{
					if (src == Register.AX)
					{
						// 16 bit multiply
						// store result in DX:AX
						ulong ret = aluDstU * aluSrcU;
						setReg(Register.RAX, ret & 0xFFFF);
						ret >>= 16;
						setReg(Register.RDX, ret & 0xFFFF);

						if (rdx.i64 != 0)
						{
							rflags.carry = 1;
							rflags.overflow = 1;
						}
						else
						{
							rflags.carry = 0;
							rflags.overflow = 0;
						}
					}
					else if (src == Register.EAX)
					{
						// 32 bit multiply
						// store result in EDX:EAX
						ulong ret = aluDstU * aluSrcU;
						setReg(Register.RAX, ret & 0xFFFFFFFF);
						ret >>= 32;
						setReg(Register.RDX, ret & 0xFFFFFFFF);

						if (rdx.i64 != 0)
						{
							rflags.carry = 1;
							rflags.overflow = 1;
						}
						else
						{
							rflags.carry = 0;
							rflags.overflow = 0;
						}
					}
				}

				break;

				// DIV
				// Unsigned Divide
			case Opcode.Div:

				mixin(getAluSrcU!());

				// Divide AX, DX:AX, EDX:EAX, or RDX:RAX by aluSrcU (based on dst)
				// Store Quotient in AL, AX, EAX, and RAX (dst)
				// Store Remainder in AH, DX, EDX, RDX (based on dst)

				if (dst == Register.AL)
				{
					// 8 bit divide

					// AX / aluSrcU
					// Quotient: AL
					// Remainder: AH

					ulong ret;

					getRegU(Register.AX, ret);

					ulong quot = ret / aluSrcU;
					ulong rem = ret % aluSrcU;

					setReg(Register.AL, quot);
					setReg(Register.AH, rem);
				}
				else
				{
					if (dst == Register.AX)
					{
						// 16 bit divide

						// DX:AX / aluSrcU
						// Quotient: AX
						// Remainder: DX

						ulong ret;
						ulong lo;

						getRegU(Register.DX, ret);
						getRegU(Register.AX, lo);

						ret <<= 16;
						ret |= (lo & 0xFFFF);

						ulong quot = ret / aluSrcU;
						ulong rem = ret % aluSrcU;

						setReg(Register.AX, quot);
						setReg(Register.DX, rem);
					}
					else if (dst == Register.EAX)
					{
						// 32 bit divide

						// EDX:EAX / aluSrcU
						// Quotient: EAX
						// Remainder: EDX

						ulong ret;
						ulong lo;

						getRegU(Register.EDX, ret);
						getRegU(Register.EAX, lo);

						ret <<= 32;
						ret |= (lo & 0xFFFFFFFF);

						ulong quot = ret / aluSrcU;
						ulong rem = ret % aluSrcU;

						setReg(Register.EAX, quot);
						setReg(Register.EDX, rem);
					}
				}

				break;








				// Bit Manipulation

				// BT
				// Bit Test
			//case Opcode.Bt:



				break;


				// Incremental Moves and Loads

				// MOVS
				// Move String
		case Opcode.Movs:

				Prefix seg = Prefix.SegDS;

				//writef("MOVS : "); //Memory.segmentRegisters[seg&0x1f].i64
			//	writef("src: 0x%x", ds.i64, ":%x", rsi.i64, " ");
			//	writef("dst: 0x%x", es.i64, ":%x", rdi.i64, " ");

				// look for prefix
				if (pfix & 0x1F)
				{
					seg = cast(Prefix)(pfix & 0x1F);
				}

				do
				{

					// copy value from DS:RSI to ES:RDI
					if (src == Register.SI)
					{
						// byte copy from seg:RSI to ES:RDI

						ubyte val = Memory.readSeg8(rsi.i64,seg);
						//writef("%x", val, " ");
						Memory.writeSeg8(rdi.i64,val,Prefix.SegES);

						// increment / decrement rdi, rsi
						if (rflags.direction)
						{
							// decrement
							rsi.i64--;
							rdi.i64--;
						}
						else
						{
							// increment
							rsi.i64++;
							rdi.i64++;
						}

						if (mode == Mode.Real)
						{
							rsi.i64&=0xffff;
							rdi.i64&=0xffff;
						}
						else if (mode == Mode.Protected)
						{
							rsi.i64&=0xffffffff;
							rdi.i64&=0xffffffff;
						}
						else
						{
						}
					}
					else
					{
						// word copy
						//writef("word MOVS");

						// copy from seg:RSI to ES:RDI

						if (mode == Mode.Real)
						{
							// 16 bit

							ushort val = Memory.readSeg16(rsi.i64,seg);
							Memory.writeSeg16(rdi.i64,val,Prefix.SegES);

							// increment / decrement rdi, rsi
							if (rflags.direction)
							{
								// decrement
								rsi.i64-=2;
								rdi.i64-=2;
							}
							else
							{
								// increment
								rsi.i64+=2;
								rdi.i64+=2;
							}
							rsi.i64&=0xffff;
							rdi.i64&=0xffff;
						}
						else if (mode == Mode.Protected)
						{
							// 32 bit

							uint val = Memory.readSeg32(rsi.i64,seg);
							Memory.writeSeg32(rdi.i64,val,Prefix.SegES);

							// increment / decrement rdi, rsi
							if (rflags.direction)
							{
								// decrement
								rsi.i64-=4;
								rdi.i64-=4;
							}
							else
							{
								// increment
								rsi.i64+=4;
								rdi.i64+=4;
							}
							rsi.i64&=0xffffffff;
							rdi.i64&=0xffffffff;
						}
						else
						{
							// 64 bit

							ulong val = Memory.readSeg64(rsi.i64,seg);
							Memory.writeSeg64(rdi.i64,val,Prefix.SegES);

							// increment / decrement rdi, rsi
							if (rflags.direction)
							{
								// decrement
								rsi.i64-=8;
								rdi.i64-=8;
							}
							else
							{
								// increment
								rsi.i64+=8;
								rdi.i64+=8;
							}
						}
					}


					// check for the REPEAT prefixes
					if (pfix & Prefix.Rep)
					{
						rcx.i64--;
						//writef("rcx--: ", rcx.i64, "\n");
						if (rcx.i64 == 0) { break; }
					}
					else
					{
						break;
					}

				} while (true);

				//writef("");

				break;

				// LODS
				// Load String
		case Opcode.Lods:

				Prefix seg = Prefix.SegDS;

				//writef("LODS : "); //Memory.segmentRegisters[seg&0x1f].i64
				//writef("src: 0x%x", ds.i64, ":%x", rsi.i64, " ");
				//writef("dst: 0x%x", es.i64, ":%x", rdi.i64, " ");

				// look for prefix
				if (pfix & 0x1F)
				{
					seg = cast(Prefix)(pfix & 0x1F);
				}

				do
				{

					// copy value from DS:RSI to RAX
					if (src == Register.AL)
					{
						// byte copy from seg:RSI to AL

						ubyte val = Memory.readSeg8(rsi.i64,seg);
		//				writef("al = ", val, "\n");
						setReg(Register.AL, val);

						// increment / decrement rdi, rsi
						if (rflags.direction)
						{
							// decrement
							rsi.i64--;
							//rdi.i64--;
						}
						else
						{
							// increment
							rsi.i64++;
							//rdi.i64++;
						}

						if (mode == Mode.Real)
						{
							rsi.i64&=0xffff;
							//rdi.i64&=0xffff;
						}
						else if (mode == Mode.Protected)
						{
							rsi.i64&=0xffffffff;
							//rdi.i64&=0xffffffff;
						}
						else
						{
						}
					}
					else
					{
						// word load

						// copy from seg:RSI to AX

						if (mode == Mode.Real)
						{
							// 16 bit

							ushort val = Memory.readSeg16(rsi.i64,seg);
//							writef("ax = ", val, "\n");
							setReg(Register.RAX, val);

							// increment / decrement rdi, rsi
							if (rflags.direction)
							{
								// decrement
								rsi.i64-=2;
								//rdi.i64-=2;
							}
							else
							{
								// increment
								rsi.i64+=2;
								//rdi.i64+=2;
							}
							rsi.i64&=0xffff;
							//rdi.i64&=0xffff;
						}
						else if (mode == Mode.Protected)
						{
							// 32 bit

							uint val = Memory.readSeg32(rsi.i64,seg);
							setReg(Register.RAX, val);

							// increment / decrement rdi, rsi
							if (rflags.direction)
							{
								// decrement
								rsi.i64-=4;
								//rdi.i64-=4;
							}
							else
							{
								// increment
								rsi.i64+=4;
								//rdi.i64+=4;
							}
							rsi.i64&=0xffffffff;
							//rdi.i64&=0xffffffff;
						}
						else
						{
							// 64 bit

							ulong val = Memory.readSeg64(rsi.i64,seg);
							setReg(Register.RAX, val);

							// increment / decrement rdi, rsi
							if (rflags.direction)
							{
								// decrement
								rsi.i64-=8;
								//rdi.i64-=8;
							}
							else
							{
								// increment
								rsi.i64+=8;
								//rdi.i64+=8;
							}
						}
					}


					// check for the REPEAT prefixes
					if (pfix & Prefix.Rep)
					{
						rcx.i64--;
						if (mode == Mode.Real)
						{
							if (rcx.i16 == 0) { break; }
						}
						else
						{
							if (rcx.i32 == 0) { break; }
						}
					}
					else
					{
						break;
					}

				} while (true);

				writef("");

				break;

				// STOS
				// Store String
			case Opcode.Stos:

				//writef("STOS : "); //Memory.segmentRegisters[seg&0x1f].i64
				//writef("src: 0x%x", ds.i64, ":%x", rsi.i64, " ");
				//writef("dst: 0x%x", es.i64, ":%x", rdi.i64, " ");

				mixin(getAluSrcU!());

				do {

					// copy value from AL to ES:RDI
					if (src == Register.AL)
					{
						// byte copy from AL to ES:RDI

						//writef("%x", aluSrcU, " ");
						Memory.writeSeg8(rdi.i64,aluSrcU,Prefix.SegES);

						// increment / decrement rdi, rsi
						if (rflags.direction)
						{
							// decrement
							rdi.i64--;
						}
						else
						{
							// increment
							rdi.i64++;
						}

						if (mode == Mode.Real)
						{
							rdi.i64&=0xffff;
						}
						else if (mode == Mode.Protected)
						{
							rdi.i64&=0xffffffff;
						}
						else
						{
						}
					}
					else
					{
						// word copy
					//	writef("word MOVS");

						// copy from seg:RSI to ES:RDI

						if (mode == Mode.Real)
						{
							// 16 bit

							Memory.writeSeg16(rdi.i64,aluSrcU,Prefix.SegES);

							// increment / decrement rdi, rsi
							if (rflags.direction)
							{
								// decrement
								rdi.i64-=2;
							}
							else
							{
								// increment
								rdi.i64+=2;
							}
							rdi.i64&=0xffff;
						}
						else if (mode == Mode.Protected)
						{
							// 32 bit

							Memory.writeSeg32(rdi.i64,aluSrcU,Prefix.SegES);

							// increment / decrement rdi, rsi
							if (rflags.direction)
							{
								// decrement
								rdi.i64-=4;
							}
							else
							{
								// increment
								rdi.i64+=4;
							}
							rdi.i64&=0xffffffff;
						}
						else
						{
							// 64 bit

							Memory.writeSeg64(rdi.i64,aluSrcU,Prefix.SegES);

							// increment / decrement rdi, rsi
							if (rflags.direction)
							{
								// decrement
								rdi.i64-=8;
							}
							else
							{
								// increment
								rdi.i64+=8;
							}
						}
					}


					// check for the REPEAT prefixes
					if (pfix & Prefix.Rep)
					{
						rcx.i64--;
						if (rcx.i64 == 0) { break; }
					}
					else
					{
						break;
					}

				} while (true);

				//writef("");

				break;

				// SCAS
				// Scan String
			case Opcode.Scas:

				//ritef("STOS : "); //Memory.segmentRegisters[seg&0x1f].i64
				//writef("src: 0x%x", ds.i64, ":%x", rsi.i64, " ");
				//writef("dst: 0x%x", es.i64, ":%x", rdi.i64, " ");

				mixin(getAluDstU!());
				mixin(getAluDst!());

				do {

					// compare value from AL to ES:RDI
					if (dst == Register.AL)
					{
						ulong val = Memory.readSeg8(rdi.i64,Prefix.SegES);
						aluSrc = cast(long)val;

						if (mode == Mode.Real)
						{
							if ((aluDstU - val) & 0x80)
							{
								rflags.sign = 1;
							}
							else
							{
								rflags.sign = 0;
							}
						}
						else if (mode == Mode.Protected)
						{
						}
						else // long
						{

						}

						if (aluDstU > val)
						{
							rflags.carry = 0;
							rflags.zero = 0;
						}
						else if (aluDstU == val)
						{
							rflags.carry = 0;
							rflags.zero = 1;
						}
						else
						{
							rflags.carry = 1;
							rflags.zero = 0;
						}

						if (aluDst > aluSrc)
						{
							rflags.overflow = rflags.sign;
						}
						else if (aluDst == aluSrc)
						{
							rflags.overflow = 0;
						}
						else
						{
							rflags.overflow = !rflags.sign;
						}

						rflags.parity = parityCheck[(cast(ubyte*)&aluDstU)[0]];

						aluDstU &= 0xf;
						aluSrcU = val & 0xf;

						if (aluDstU > aluSrcU)
						{
							rflags.aux = 0;
						}
						else if (aluDstU == aluSrcU)
						{
							rflags.aux = 0;
						}
						else
						{
							rflags.aux = 1;
						}

						// increment / decrement rdi, rsi
						if (rflags.direction)
						{
							// decrement
							rdi.i64--;
						}
						else
						{
							// increment
							rdi.i64++;
						}

						if (mode == Mode.Real)
						{
							rdi.i64&=0xffff;
						}
						else if (mode == Mode.Protected)
						{
							rdi.i64&=0xffffffff;
						}
						else
						{
						}
					}
					else
					{
						// word compare

						// compare from seg:RSI to ES:RDI

						if (mode == Mode.Real)
						{
							// 16 bit

							ulong val = Memory.readSeg16(rdi.i64,Prefix.SegES);

							aluSrc = cast(long)val;

							if (mode == Mode.Real)
							{
								if ((aluDstU - val) & 0x8000)
								{
									rflags.sign = 1;
								}
								else
								{
									rflags.sign = 0;
								}
							}
							else if (mode == Mode.Protected)
							{
							}
							else // long
							{

							}

							if (aluDstU > val)
							{
								rflags.carry = 0;
								rflags.zero = 0;
							}
							else if (aluDstU == val)
							{
								rflags.carry = 0;
								rflags.zero = 1;
							}
							else
							{
								rflags.carry = 1;
								rflags.zero = 0;
							}

							if (aluDst > aluSrc)
							{
								rflags.overflow = rflags.sign;
							}
							else if (aluDst == aluSrc)
							{
								rflags.overflow = 0;
							}
							else
							{
								rflags.overflow = !rflags.sign;
							}

							rflags.parity = parityCheck[(cast(ubyte*)&aluDstU)[0]];

							aluDstU &= 0xf;
							aluSrcU = val & 0xf;

							if (aluDstU > aluSrcU)
							{
								rflags.aux = 0;
							}
							else if (aluDstU == aluSrcU)
							{
								rflags.aux = 0;
							}
							else
							{
								rflags.aux = 1;
							}

							// increment / decrement rdi, rsi
							if (rflags.direction)
							{
								// decrement
								rdi.i64-=2;
							}
							else
							{
								// increment
								rdi.i64+=2;
							}
							rdi.i64&=0xffff;
						}
						else if (mode == Mode.Protected)
						{
							// 32 bit

							ulong val = Memory.readSeg32(rdi.i64,Prefix.SegES);

							// increment / decrement rdi, rsi
							if (rflags.direction)
							{
								// decrement
								rdi.i64-=4;
							}
							else
							{
								// increment
								rdi.i64+=4;
							}
							rdi.i64&=0xffffffff;
						}
						else
						{
							// 64 bit

							ulong val = Memory.readSeg64(rdi.i64,Prefix.SegES);

							// increment / decrement rdi, rsi
							if (rflags.direction)
							{
								// decrement
								rdi.i64-=8;
							}
							else
							{
								// increment
								rdi.i64+=8;
							}
						}
					}


					// check for the REPEAT prefixes
					if (pfix & Prefix.Rep)
					{
						rcx.i64--;
						if (rcx.i64 == 0) { break; }
					}
					else
					{
						break;
					}

				} while (true);

				writef("");

				break;







				// Flags

				// CLC
				// Clear Carry Flag
			case Opcode.Clc:

				rflags.carry = 0;

				break;

				// STC
				// Set Carry Flag
			case Opcode.Stc:

				rflags.carry = 1;

				break;

				// CMC
				// Complement Carry Flag
			case Opcode.Cmc:

				rflags.carry = !rflags.carry;

				break;

				// CLD
				// Clear Direction Flag
			case Opcode.Cld:

				rflags.direction = 0;

				break;

				// STD
				// Set Direction Flag
			case Opcode.Std:

				rflags.direction = 1;

				break;












				// Jumps

				// immediate value is relative address (in src)

				// JZ / JE
				// Jump If Zero / Jump If Equal
			case Opcode.Jz:

				if (rflags.zero)
				{
					mixin(getAluSrc!());
					//writef("jump ", aluSrc);
					Memory.advanceRip(aluSrc);
				}

				break;

				// JNZ / JNE
				// Jump If Not Zero / Jump If Not Equal
			case Opcode.Jnz:

				if (!rflags.zero)
				{
					mixin(getAluSrc!());
					//writef("jump ", aluSrc);
					Memory.advanceRip(aluSrc);
				}

				break;

				// JO
				// Jump If Overflow
			case Opcode.Jo:

				if (rflags.overflow)
				{
					mixin(getAluSrc!());
					//writef("jump ", aluSrc);
					Memory.advanceRip(aluSrc);
				}

				break;

				// JNO
				// Jump If No Overflow
			case Opcode.Jno:

				if (!rflags.overflow)
				{
					mixin(getAluSrc!());
					//writef("jump ", aluSrc);
					Memory.advanceRip(aluSrc);
				}

				break;

				// JB / JC / JNAE
				// Jump If Below / Jump If Carry / Jump If Not Above or Equal
			case Opcode.Jb:

				if (rflags.carry)
				{
					mixin(getAluSrc!());
					//writef("jump ", aluSrc);
					Memory.advanceRip(aluSrc);
				}

				break;

				// JNB / JNC / JAE
				// Jump If Not Below / Jump If No Carry	/ Jump If Above or Equal
			case Opcode.Jnb:

				if (rflags.carry)
				{
					mixin(getAluSrc!());
					//writef("jump ", aluSrc);
					Memory.advanceRip(aluSrc);
				}

				break;

				// JBE / JNA
				// Jump If Below or Equal / Jump If Not Above
			case Opcode.Jbe:

				if (rflags.carry || rflags.zero)
				{
					mixin(getAluSrc!());
					//writef("jump ", aluSrc);
					Memory.advanceRip(aluSrc);
				}

				break;

				// JNBE / JA
				// Jump If Not Below or Equal / Jump If Above
			case Opcode.Jnbe:

				if (!rflags.carry && !rflags.zero)
				{
					mixin(getAluSrc!());
					//writef("jump ", aluSrc);
					Memory.advanceRip(aluSrc);
				}

				break;

				// JS
				// Jump If Sign
			case Opcode.Js:

				if (rflags.sign)
				{
					mixin(getAluSrc!());
					//writef("jump ", aluSrc);
					Memory.advanceRip(aluSrc);
				}

				break;

				// JNS
				// Jump If Not Sign
			case Opcode.Jns:

				if (!rflags.sign)
				{
					mixin(getAluSrc!());
					//writef("jump ", aluSrc);
					Memory.advanceRip(aluSrc);
				}

				break;

				// JP / JPE
				// Jump If Parity / Jump If Parity Even
			case Opcode.Jp:

				if (rflags.parity)
				{
					mixin(getAluSrc!());
					//writef("jump ", aluSrc);
					Memory.advanceRip(aluSrc);
				}

				break;

				// JNP / JPO
				// Jump If Not Parity / Jump If Parity Odd
			case Opcode.Jnp:

				if (!rflags.parity)
				{
					mixin(getAluSrc!());
					//writef("jump ", aluSrc);
					Memory.advanceRip(aluSrc);
				}

				break;

				// JL / JNGE
				// Jump If Less / Jump If Not Greater Or Equal
			case Opcode.Jl:

				if (rflags.sign != rflags.overflow)
				{
					mixin(getAluSrc!());
					//writef("jump ", aluSrc);
					Memory.advanceRip(aluSrc);
				}

				break;

				// JNL / JGE
				// Jump If Not Less / Jump If Greater Or Equal
			case Opcode.Jnl:

				if (rflags.sign == rflags.overflow)
				{
					mixin(getAluSrc!());
					//writef("jump ", aluSrc);
					Memory.advanceRip(aluSrc);
				}

				break;

				// JLE / JNG
				// Jump If Less Or Equal / Jump If Not Greater
			case Opcode.Jle:

				if (rflags.zero || (rflags.sign != rflags.overflow))
				{
					mixin(getAluSrc!());
					//writef("jump ", aluSrc);
					Memory.advanceRip(aluSrc);
				}

				break;

				// JNLE / JG
				// Jump If Not Less Or Equal / Jump If Greater
			case Opcode.Jnle:

				if (!rflags.zero && (rflags.sign == rflags.overflow))
				{
					mixin(getAluSrc!());
					//writef("jump ", aluSrc);
					Memory.advanceRip(aluSrc);
				}

				break;

				// JMP
				// Jump (near, far)
			case Opcode.Jmp:

				if (accDst == Access.Null)
				{
					// JMP

					// if it is a register or memory address, it becomes new RIP
					// otherwise, it is added to current RIP

					mixin(getAluSrc!());

					if (accSrc == Access.Imm8 ||
						accSrc == Access.Imm16 ||
						accSrc == Access.Imm32 ||
						accSrc == Access.Imm64)
					{
						Memory.advanceRip(aluSrc);
						//writef("jump %x", aluSrc);
					}
					else
					{
						rip.i16 = aluSrc;
						//writef("jump TO %x", aluSrc);
					}

				}
				else
				{
					// JMP FAR
				}
				break;





				// Routines

				// CALL
			case Opcode.Call:

				if (skipLine) { nestedCallCount++; }
				else if (skipCall) { skipLine = true; nestedCallCount++; }

				if (accDst == Access.Null)
				{
					// CALL NEAR

					mixin(getAluSrc!());

					//writef("call (near) 0x%x", aluSrc, " (rip + %d)", aluSrc);

					// Push RIP

					if (mode == Mode.Real)
					{
						Stack.pushW(rip.i64);
					}
					else if (mode == Mode.Protected)
					{
						Stack.pushD(rip.i64);
					}
					else
					{
						Stack.pushQ(rip.i64);
					}

					Memory.advanceRip(aluSrc);
				}
				else
				{
					// CALL FAR

					writef("call (far) 0x%x", dst);
				}

				break;

			case Opcode.Ret:

				if (skipLine) { nestedCallCount--;
					if (nestedCallCount==0) { skipLine = false; }
				}

				if (mode == Mode.Real)
				{
					rip.i16 = Stack.popW();
				}
				else if (mode == Mode.Protected)
				{
					rip.i32 = Stack.popD();
				}
				else
				{
					rip.i64 = Stack.popQ();
				}

				break;

			case Opcode.Leave:
				rsp.i64 = rbp.i64;

				if (mode == Mode.Real)
				{
					rbp.i16 = Stack.popW();
				}
				else if (mode == Mode.Protected)
				{
					rbp.i32 = Stack.popD();
				}
				else
				{
					rbp.i64 = Stack.popQ();
				}
				break;

			case Opcode.Enter:

				// source : temp_ALLOC_SPACE (AMD)
				// third  : temp_LEVEL

				// aluSrc = temp_ALLOC_SPACE
				mixin(getAluSrcU!());

				// aluThree = temp_LEVEL
				mixin(getAluThree!());

				aluThree &= 0x1f;

				ulong old_rbp = rbp.i64;

				// Push RBP

				if (mode == Mode.Real)
				{
					Stack.pushW(rbp.i64);
				}
				else if (mode == Mode.Protected)
				{
					Stack.pushD(rbp.i64);
				}
				else
				{
					Stack.pushQ(rbp.i64);
				}

				ulong temp_rbp = rsp.i64;

				if (aluThree > 0)
				{
					if (mode == Mode.Real)
					{
						for (int i = 1; i < aluThree; i++)
						{
							Stack.pushW(Memory.readStack16(old_rbp - (i*2)));
						}
						Stack.pushW(temp_rbp);
					}
					else if (mode == Mode.Protected)
					{
						for (int i = 1; i < aluThree; i++)
						{
							Stack.pushD(Memory.readStack32(old_rbp - (i*4)));
						}
						Stack.pushD(temp_rbp);
					}
					else
					{
						for (int i = 1; i < aluThree; i++)
						{
							Stack.pushQ(Memory.readStack64(old_rbp - (i*8)));
						}
						Stack.pushQ(temp_rbp);
					}
				}
				rsp.i64 -= aluSrcU;

				// an actual cpu does a write check on SS:RSP
				// just to validate that it has write privileges

				rbp.i64 = temp_rbp;


				break;

			case Opcode.Int:
				mixin(getAluSrcU!());
				writef("Int: ", aluSrcU, "\n");
				break;

			case Opcode.Iret:
				//printAll();

				return 0;
				break;

			default:
				writef(opcodeNames[op], " UNIMPL");
				break;
		}

		old_rip = rip.i64;
		old_trans = Memory.translateRip();
	}

	return 0;
}




template getAlu(char[] s, char[] u)
{
	const char[] getAlu = `
		if (acc` ~ Capitalize!(s) ~ ` == Access.Imm8)
		{
			// immediate (8-bit)

			alu` ~ Capitalize!(s) ~ u ~ ` = cast(` ~ (u.length == 0 ? "" : "u") ~ `byte)` ~ s ~ `;
		}
		else if (acc` ~ Capitalize!(s) ~ ` == Access.Imm16)
		{
			// immediate (8-bit)

			alu` ~ Capitalize!(s) ~ u ~ ` = cast(` ~ (u.length == 0 ? "" : "u") ~ `short)` ~ s ~ `;
		}
		else if (acc` ~ Capitalize!(s) ~ ` == Access.Imm32)
		{
			// immediate (8-bit)

			alu` ~ Capitalize!(s) ~ u ~ ` = cast(` ~ (u.length == 0 ? "" : "u") ~ `int)` ~ s ~ `;
		}
		else if (acc` ~ Capitalize!(s) ~ ` == Access.Imm64)
		{
			// immediate (8-bit)

			alu` ~ Capitalize!(s) ~ u ~ ` = ` ~ s ~ `;
		}
		else if (acc` ~ Capitalize!(s) ~ ` == Access.Addr)
		{
			// pointer

			getRegU(` ~ s ~ `, effectiveAddress);

			if (mode == Mode.Real)
			{
				// read 16 bit
				if (pfix & 0x1f) {
					//writef("using prefix: %x", pfix);
					alu` ~ Capitalize!(s) ~ u ~ ` = Memory.readSeg16(effectiveAddress, pfix);
				}
				else
				{
					if (` ~ s ~ ` == Register.BP || ` ~ s ~ ` == Register.SP)
					{
						alu` ~ Capitalize!(s) ~ u ~ ` = Memory.readStack16(effectiveAddress);
					}
					else
					{
						alu` ~ Capitalize!(s) ~ u ~ ` = Memory.readMem16(effectiveAddress);
					}
				}
			}
			else if (mode == Mode.Protected)
			{
				// read 32 bit
				alu` ~ Capitalize!(s) ~ u ~ ` = Memory.readMem32(effectiveAddress);
			}
			else
			{
				// long mode
				// read 64 bit
				alu` ~ Capitalize!(s) ~ u ~ ` = Memory.readMem64(effectiveAddress);
			}
		}
		else if (acc` ~ Capitalize!(s) ~ ` == Access.Offset)
		{
			// relative offset addressing

			getRegU(` ~ s ~ `, effectiveAddress);
			effectiveAddress += disp;

			if (mode == Mode.Real)
			{
				// read 16 bit
				if (pfix & 0x1f) {
					//writef("using prefix: %x", pfix);
					alu` ~ Capitalize!(s) ~ u ~ ` = Memory.readSeg16(effectiveAddress, pfix);
				}
				else
				{
					if (` ~ s ~ ` == Register.BP || ` ~ s ~ ` == Register.SP)
					{
						alu` ~ Capitalize!(s) ~ u ~ ` = Memory.readStack16(effectiveAddress);
					}
					else
					{
						alu` ~ Capitalize!(s) ~ u ~ ` = Memory.readMem16(effectiveAddress);
					}
				}
			}
			else if (mode == Mode.Protected)
			{
				// read 32 bit
				alu` ~ Capitalize!(s) ~ u ~ ` = Memory.readMem32(effectiveAddress);
			}
			else
			{
				// long mode
				// read 64 bit
				alu` ~ Capitalize!(s) ~ u ~ ` = Memory.readMem64(effectiveAddress);
			}
		}
		else if (acc` ~ Capitalize!(s) ~ ` == Access.OffsetSI)
		{
			// relative offset addressing

			getRegU(` ~ s ~ `, effectiveAddress);
			effectiveAddress += disp + rsi.i64;

			if (mode == Mode.Real)
			{
				// read 16 bit
				if (pfix & 0x1f) {
					//writef("using prefix: %x", pfix);
					alu` ~ Capitalize!(s) ~ u ~ ` = Memory.readSeg16(effectiveAddress, pfix);
				}
				else
				{
					if (` ~ s ~ ` == Register.BP || ` ~ s ~ ` == Register.SP)
					{
						alu` ~ Capitalize!(s) ~ u ~ ` = Memory.readStack16(effectiveAddress);
					}
					else
					{
						alu` ~ Capitalize!(s) ~ u ~ ` = Memory.readMem16(effectiveAddress);
					}
				}
			}
			else if (mode == Mode.Protected)
			{
				// read 32 bit
				alu` ~ Capitalize!(s) ~ u ~ ` = Memory.readMem32(effectiveAddress);
			}
			else
			{
				// long mode
				// read 64 bit
				alu` ~ Capitalize!(s) ~ u ~ ` = Memory.readMem64(effectiveAddress);
			}
		}
		else if (acc` ~ Capitalize!(s) ~ ` == Access.OffsetDI)
		{
			// relative offset addressing

			getRegU(` ~ s ~ `, effectiveAddress);
			effectiveAddress += disp + rdi.i64;

			if (mode == Mode.Real)
			{
				// read 16 bit
				if (pfix & 0x1f) {
					//writef("using prefix: %x", pfix);
					alu` ~ Capitalize!(s) ~ u ~ ` = Memory.readSeg16(effectiveAddress, pfix);
				}
				else
				{
					if (` ~ s ~ ` == Register.BP || ` ~ s ~ ` == Register.SP)
					{
						alu` ~ Capitalize!(s) ~ u ~ ` = Memory.readStack16(effectiveAddress);
					}
					else
					{
						alu` ~ Capitalize!(s) ~ u ~ ` = Memory.readMem16(effectiveAddress);
					}
				}
			}
			else if (mode == Mode.Protected)
			{
				// read 32 bit
				alu` ~ Capitalize!(s) ~ u ~ ` = Memory.readMem32(effectiveAddress);
			}
			else
			{
				// long mode
				// read 64 bit
				alu` ~ Capitalize!(s) ~ u ~ ` = Memory.readMem64(effectiveAddress);
			}
		}
		else if (acc` ~ Capitalize!(s) ~ ` == Access.Reg)
		{
			// register value

			getReg` ~ u ~ `(` ~ s ~ `, alu` ~ Capitalize!(s) ~ u ~ `);
		}
	`;
}

template setAlu(char[] s, char[] u)
{
	const char[] setAlu = `
		if (acc` ~ Capitalize!(s) ~ ` == Access.Imm8	||
			acc` ~ Capitalize!(s) ~ ` == Access.Imm16	||
			acc` ~ Capitalize!(s) ~ ` == Access.Imm32	||
			acc` ~ Capitalize!(s) ~ ` == Access.Imm64 )
		{
			assert(false, "Attempt to set an immediate");
		}
		else if (acc` ~ Capitalize!(s) ~ ` == Access.Addr)
		{
			// pointer
			getRegU(` ~ s ~ `, effectiveAddress);

			if (mode == Mode.Real)
			{
				// write 16 bit
				if (pfix & 0x1F) { // using a segment override
					//writef("(0x%x", Memory.segmentRegisters[pfix].i64, ":%x", effectiveAddress,") = 0x%x", alu` ~ Capitalize!(s) ~ u ~ `);
					if (src < Register.AX)
					{
						Memory.writeSeg8(effectiveAddress, alu` ~ Capitalize!(s) ~ u ~ `, pfix);
					}
					else
					{
						Memory.writeSeg16(effectiveAddress, alu` ~ Capitalize!(s) ~ u ~ `, pfix);
					}
				}
				else
				{
					if (` ~ s ~ ` == Register.BP || ` ~ s ~ ` == Register.SP)
					{
						//writef("(0x%x[SS]", ss.i64, ":%x", effectiveAddress,") = 0x%x", alu` ~ Capitalize!(s) ~ u ~ `);
						if (src < Register.AX)
						{
							Memory.writeStack8(effectiveAddress, alu` ~ Capitalize!(s) ~ u ~ `);
						}
						else
						{
							Memory.writeStack16(effectiveAddress, alu` ~ Capitalize!(s) ~ u ~ `);
						}
					}
					else
					{
						//writef("(0x%x[DS]", ds.i64, ":%x", effectiveAddress,") = 0x%x", alu` ~ Capitalize!(s) ~ u ~ `);
						if (src < Register.AX)
						{
							Memory.writeMem8(effectiveAddress, alu` ~ Capitalize!(s) ~ u ~ `);
						}
						else
						{
							Memory.writeMem16(effectiveAddress, alu` ~ Capitalize!(s) ~ u ~ `);
						}
					}
				}
			}
			else if (mode == Mode.Protected)
			{
				// write 32 bit
				Memory.writeMem32(effectiveAddress, alu` ~ Capitalize!(s) ~ u ~ `);
			}
			else
			{
				// long mode
				// write 64 bit
				Memory.writeMem64(effectiveAddress, alu` ~ Capitalize!(s) ~ u ~ `);
			}
		}
		else if (acc` ~ Capitalize!(s) ~ ` == Access.Offset)
		{
			// reg + offset (relative addressing)
			getRegU(` ~ s ~ `, effectiveAddress);
			effectiveAddress += disp;

			if (mode == Mode.Real)
			{
				// write 16 bit
				if (pfix & 0x1F) { // using a segment override
					//writef("(0x%x", Memory.segmentRegisters[pfix].i64, ":%x", effectiveAddress,") = 0x%x", alu` ~ Capitalize!(s) ~ u ~ `);
					if (src < Register.AX)
					{
						Memory.writeSeg8(effectiveAddress, alu` ~ Capitalize!(s) ~ u ~ `, pfix);
					}
					else
					{
						Memory.writeSeg16(effectiveAddress, alu` ~ Capitalize!(s) ~ u ~ `, pfix);
					}
				}
				else
				{
					if (` ~ s ~ ` == Register.BP || ` ~ s ~ ` == Register.SP)
					{
						//writef("(0x%x[SS]", ss.i64, ":%x", effectiveAddress,") = 0x%x", alu` ~ Capitalize!(s) ~ u ~ `);
						if (src < Register.AX)
						{
							Memory.writeStack8(effectiveAddress, alu` ~ Capitalize!(s) ~ u ~ `);
						}
						else
						{
							Memory.writeStack16(effectiveAddress, alu` ~ Capitalize!(s) ~ u ~ `);
						}
					}
					else
					{
						//writef("(0x%x[DS]", ds.i64, ":%x", effectiveAddress,") = 0x%x", alu` ~ Capitalize!(s) ~ u ~ `);
						if (src < Register.AX)
						{
							Memory.writeMem8(effectiveAddress, alu` ~ Capitalize!(s) ~ u ~ `);
						}
						else
						{
							Memory.writeMem16(effectiveAddress, alu` ~ Capitalize!(s) ~ u ~ `);
						}
					}
				}
			}
			else if (mode == Mode.Protected)
			{
				// write 32 bit
				Memory.writeMem32(effectiveAddress, alu` ~ Capitalize!(s) ~ u ~ `);
			}
			else
			{
				// long mode
				// write 64 bit
				Memory.writeMem64(effectiveAddress, alu` ~ Capitalize!(s) ~ u ~ `);
			}
		}
		else if (acc` ~ Capitalize!(s) ~ ` == Access.OffsetSI)
		{
			// reg + offset (relative addressing)
			getRegU(` ~ s ~ `, effectiveAddress);
			effectiveAddress += disp + rsi.i64;

			if (mode == Mode.Real)
			{
				// write 16 bit
				if (pfix & 0x1F) { // using a segment override
					//writef("(0x%x", Memory.segmentRegisters[pfix].i64, ":%x", effectiveAddress,") = 0x%x", alu` ~ Capitalize!(s) ~ u ~ `);
					if (src < Register.AX)
					{
						Memory.writeSeg8(effectiveAddress, alu` ~ Capitalize!(s) ~ u ~ `, pfix);
					}
					else
					{
						Memory.writeSeg16(effectiveAddress, alu` ~ Capitalize!(s) ~ u ~ `, pfix);
					}
				}
				else
				{
					if (` ~ s ~ ` == Register.BP || ` ~ s ~ ` == Register.SP)
					{
						//writef("(0x%x[SS]", ss.i64, ":%x", effectiveAddress,") = 0x%x", alu` ~ Capitalize!(s) ~ u ~ `);
						if (src < Register.AX)
						{
							Memory.writeStack8(effectiveAddress, alu` ~ Capitalize!(s) ~ u ~ `);
						}
						else
						{
							Memory.writeStack16(effectiveAddress, alu` ~ Capitalize!(s) ~ u ~ `);
						}
					}
					else
					{
						//writef("(0x%x[DS]", ds.i64, ":%x", effectiveAddress,") = 0x%x", alu` ~ Capitalize!(s) ~ u ~ `);
						if (src < Register.AX)
						{
							Memory.writeMem8(effectiveAddress, alu` ~ Capitalize!(s) ~ u ~ `);
						}
						else
						{
							Memory.writeMem16(effectiveAddress, alu` ~ Capitalize!(s) ~ u ~ `);
						}
					}
				}
			}
			else if (mode == Mode.Protected)
			{
				// write 32 bit
				Memory.writeMem32(effectiveAddress, alu` ~ Capitalize!(s) ~ u ~ `);
			}
			else
			{
				// long mode
				// write 64 bit
				Memory.writeMem64(effectiveAddress, alu` ~ Capitalize!(s) ~ u ~ `);
			}
		}
		else if (acc` ~ Capitalize!(s) ~ ` == Access.OffsetDI)
		{
			// reg + offset (relative addressing)
			getRegU(` ~ s ~ `, effectiveAddress);
			effectiveAddress += disp + rdi.i64;

			if (mode == Mode.Real)
			{
				// write 16 bit
				if (pfix & 0x1F) { // using a segment override
					//writef("(0x%x", Memory.segmentRegisters[pfix].i64, ":%x", effectiveAddress,") = 0x%x", alu` ~ Capitalize!(s) ~ u ~ `);
					if (src < Register.AX)
					{
						Memory.writeSeg8(effectiveAddress, alu` ~ Capitalize!(s) ~ u ~ `, pfix);
					}
					else
					{
						Memory.writeSeg16(effectiveAddress, alu` ~ Capitalize!(s) ~ u ~ `, pfix);
					}
				}
				else
				{
					if (` ~ s ~ ` == Register.BP || ` ~ s ~ ` == Register.SP)
					{
						//writef("(0x%x[SS]", ss.i64, ":%x", effectiveAddress,") = 0x%x", alu` ~ Capitalize!(s) ~ u ~ `);
						if (src < Register.AX)
						{
							Memory.writeStack8(effectiveAddress, alu` ~ Capitalize!(s) ~ u ~ `);
						}
						else
						{
							Memory.writeStack16(effectiveAddress, alu` ~ Capitalize!(s) ~ u ~ `);
						}
					}
					else
					{
						//writef("(0x%x[DS]", ds.i64, ":%x", effectiveAddress,") = 0x%x", alu` ~ Capitalize!(s) ~ u ~ `);
						if (src < Register.AX)
						{
							Memory.writeMem8(effectiveAddress, alu` ~ Capitalize!(s) ~ u ~ `);
						}
						else
						{
							Memory.writeMem16(effectiveAddress, alu` ~ Capitalize!(s) ~ u ~ `);
						}
					}
				}
			}
			else if (mode == Mode.Protected)
			{
				// write 32 bit
				Memory.writeMem32(effectiveAddress, alu` ~ Capitalize!(s) ~ u ~ `);
			}
			else
			{
				// long mode
				// write 64 bit
				Memory.writeMem64(effectiveAddress, alu` ~ Capitalize!(s) ~ u ~ `);
			}
		}
		else if (acc` ~ Capitalize!(s) ~ ` == Access.Reg)
		{
			//writef(registerNames[` ~ s ~ `], " = 0x%x", alu` ~ Capitalize!(s) ~ u ~ `);
			setReg` ~ u ~ `(cast(Register)` ~ s ~ `, alu` ~ Capitalize!(s) ~ u ~ `);
		}
	`;
}

template getAluSrcU()
{
	const char[] getAluSrcU = getAlu!("src", "U");
}

template getAluSrc()
{
	const char[] getAluSrc = getAlu!("src", "");
}

template getAluThreeU()
{
	const char[] getAluThreeU = getAlu!("three", "U");
}

template getAluThree()
{
	const char[] getAluThree = getAlu!("three", "");
}

template getAluDstU()
{
	const char[] getAluDstU = getAlu!("dst", "U");
}

template getAluDst()
{
	const char[] getAluDst = getAlu!("dst", "");
}

template setAluDst()
{
	const char[] setAluDst = setAlu!("dst", "");
}

template setAluDstU()
{
	const char[] setAluDstU = setAlu!("dst", "U");
}
