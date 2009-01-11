module xombemu.x86.opcodes;


enum Opcode:ushort
{
	Null,

	Nop,

	Cax, //cbw, cwde, cdqe
	Cdx, //cwd, cdq, cqo

	PushF,
	PopF,

	PushA,
	PopA,

	Push,
	Pop,

	Add,
	Or,
	Adc,
	Sbb,
	And,
	Sub,
	Xor,

	Cmp,
	CmpSigned,
	Cmps,

	Mov,
	Movs,

	Daa,
	Aaa,
	Das,
	Aas,

	Inc,
	Dec,

	Lea,

	Les,
	Lds,

	Bound,
	Arpl,

	Jmp,

	Jo,
	Jno,
	Jb,
	Jnb,
	Jz,
	Jnz,
	Jbe,
	Jnbe,

	Js,
	Jns,
	Jp,
	Jnp,
	Jl,
	Jnl,
	Jle,
	Jnle,

	Call,

	Wait,

	Sahf,
	Lahf,

	Test,
	Xchg,

	Rol,
	Ror,
	Rcl,
	Rcr,
	Shl,
	Shr,
	Sal,
	Sar,

	Int,
	Int3,
	Into,

	Ret,
	Iret,

	Aam,
	Aad,
	Salc,
	Xlat,

	Loop,
	Loope,
	Loopne,

	Jcxz,

	In,
	Out,

	Hlt,
	Cmc,

	Mul,
	Imul,

	Div,
	Idiv,

	Not,
	Neg,

	Ins,
	Outs,

	Stos,
	Lods,
	Scas,

	Enter,
	Leave,

	Clc,
	Stc,

	Cli,
	Sti,

	Cld,
	Std,

	Cpuid,

	Bt,

}

char[][] opcodeNames = [
	"invalid",

	"nop",

	"cbx",
	"cwd",

	"pushf",
	"popf",

	"pusha",
	"popa",

	"push",
	"pop",

	"add",
	"or",
	"adc",
	"sbb",
	"and",
	"sub",
	"xor",

	"cmp",
	"cmp",
	"cmps",

	"mov",
	"movs",

	"daa",
	"aaa",
	"das",
	"aas",

	"inc",
	"dec",

	"lea",

	"les",
	"lds",

	"bound",
	"arpl",

	"jmp",

	"jo",
	"jno",
	"jb",
	"jnb",
	"jz",
	"jnz",
	"jbe",
	"jnbe",

	"js",
	"jns",
	"jp",
	"jnp",
	"jl",
	"jnl",
	"jle",
	"jnle",

	"call",

	"wait",

	"sahf",
	"lahf",

	"test",
	"xchg",

	"rol",
	"ror",
	"rcl",
	"rcr",
	"shl",
	"shr",
	"sal",
	"sar",

	"int",
	"int3",
	"into",

	"ret",
	"iret",

	"aam",
	"aad",
	"salc",
	"xlat",

	"loop",
	"loope",
	"loopne",

	"jcxz",

	"in",
	"out",

	"hlt",
	"cmc",

	"mul",
	"imul",

	"div",
	"idiv",

	"not",
	"neg",

	"ins",
	"outs",

	"stos",
	"lods",
	"scas",

	"enter",
	"leave",

	"clc",
	"stc",

	"cli",
	"sti",

	"cld",
	"std",

	"cpuid",

	"bt",
];

