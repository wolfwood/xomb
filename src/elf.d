/** This ELF header declaration is based upon the 32-bit equivalent of the standard ELF header, described in the
	following PDF document:

	http://www.pittgeeks.org/pgos/documents/elf_64.pdf
*/

/** Variable Type Definitions
The following definitions declare sizes for various types of Elf64-specific
variables. These types are defined using 64-bit specific datatypes.
They are individually commented with their corresponding number of bytes.
 */

import multiboot;

alias void* Elf64_Addr;	   // size 8
alias ulong Elf64_Off;	   // size 8
alias ushort Elf64_Half;   // size 2
alias uint Elf64_Word;	   // size 4
alias int Elf64_Sword;	   // size 4
alias ulong Elf64_Xword;   // size 8
alias long Elf64_Sxword;   // size 8


const ET_NONE = 0;
const ET_REL = 1;
const ET_EXEC = 2;
const ET_DYN = 3;
const ET_CORE = 4;
const ET_LOOS = 0xfe00;
const ET_HIOS = 0xfeff;
const ET_LOPROC = 0xff00;
const ET_HIPROC = 0xffff;

/** These values declare types of architectures, used in the e_machine field of the ELF header (see below).
These valeus represent common types of architectures, including i386 (3), Sun's SPARC (2), and MIPS (8).
 */ 
const EM_NONE = 0;
const EM_M32 = 1;
const EM_SPARC = 2;
const EM_386 = 3;
const EM_68K = 4;
const EM_88K = 5;
const EM_860 = 7;
const EM_MIPS = 8;

const EV_NONE = 0;
const EV_CURRENT = 1;

/** These constant values declare the index location of the items in the
e_ident[] array (declared in the Elf64_EHhdr structure, shown below). 
They correspond to basic information about the file. For example, E_MAG0, 
or the first magic number, is located at byte 0 of the e_ident[] array,
and declares a number to identify the binary file when loaded.
*/
const EI_MAG0 = 0;
const EI_MAG1 = 1;
const EI_MAG2 = 2;
const EI_MAG3 = 3;
const EI_CLASS = 4;
const EI_DATA = 5;
const EI_VERSION = 6;
const EI_OSABI = 7;
const EI_ABIVERSION = 8;
const EI_PAD = 9;

/** EI_NIDENT declares the size, in items, of the e_ident[] array.
For a standard 64-bit compiled Elf object file, the e_ident[] array
has 16 items.
*/
const EI_NIDENT = 16;

const ELFOSABI_SYSV = 0;
const ELFOSABI_HPUX = 1;
const ELFOSABI_STANDALONE = 255;

const ELFMAG0 = 0x7f;
const ELFMAG1 = 'E';
const ELFMAG2 = 'L';
const ELFMAG3 = 'F';

/** These constant variables declare possible values for the EI_CLASS
member of the e_ident[] array. They identify the object file as
being compiled on a 32-bit machine (ELFCLASS32), a 64-bit machine 
(ELFCLASS64), or being invalid (ELFCLASSNONE).
*/
const ELFCLASSNONE = 0;
const ELFCLASS32 = 1;
const ELFCLASS64 = 2;

const ELFDATANONE = 0;
const ELFDATA2LSB = 1;
const ELFDATA2MSB = 2;

const SHN_UNDEF = 0;
const SHN_LOPROC = 0xff00;
const SHN_HIPROC = 0xff1f;
const SHN_LOOS = 0xff20;
const SHN_HIOS = 0xff3f;
const SHN_ABS = 0xfff1;
const SHN_COMMON = 0xfff2;

/** These constants declare various types for a section in a section table.
For more information on their meaning, see their in-depth descriptions in the
ELF64 header declaration. */
const SHT_NULL = 0;
const SHT_PROGBITS = 1;
const SHT_SYMTAB = 2;
const SHT_STRTAB = 3;
const SHT_RELA = 4;
const SHT_HASH = 5;
const SHT_DYNAMIC = 6;
const SHT_NOTE = 7;
const SHT_NOBITS = 8;
const SHT_REL = 9;
const SHT_SHLIB = 10;
const SHT_DYNSYM = 11;
const SHT_LOOS = 0x60000000;
const SHT_HIOS = 0x6FFFFFFF;
const SHT_LOPROC = 0x70000000;
const SHT_HIPROC = 0x7fffffff;
const SHT_X86_64_UNWIND = 0x70000001;

/** These constants declare possible values for the section header's flags member. These values are declared below:

	SHF_WRITE: indicates that a section contains information that is directly writable during execution.

	SHF_ALLOC: indicates that a specific section must be allocated memory during execution. Some sections
		do not reside in memory during execution. In these examples, this flag would not be set.

	SHF_EXECINSTR: indicates that a specific section contains information that can be directly executed by a 
		processor (e.g. it contains machine instructions).
*/
const SHF_WRITE = 0x1;
const SHF_ALLOC = 0x2;
const SHF_EXECINSTR = 0x4;
const SHF_X86_64_LARGE = 0x10000000;
const SHF_MASKOS = 0x0f000000;
const SHF_MASKPROC = 0xf0000000;

const STB_LOCAL = 0;
const STB_GLOBAL = 1;
const STB_WEAK = 2;
const STB_LOOS = 10;
const STB_HIOS = 12;
const STB_LOPROC = 13;
const STB_HIPROC = 15;

const STT_NOTYPE = 0;
const STT_OBJECT = 1;
const STT_FUNC = 2;
const STT_SECTION = 3;
const STT_FILE = 4;
const STT_LOOS = 10;
const STT_HIOS = 12;
const STT_LOPROC = 13;
const STT_HIPROC = 15;

const R_386_NONE = 0;
const R_386_32 = 1;
const R_386_PC32 = 2;
const R_386_GOT32 = 3;
const R_386_PLT32 = 4;
const R_386_COPY = 5;
const R_386_GLOB_DAT = 6;
const R_386_JMP_SLOT = 7;
const R_386_RELATIVE = 8;
const R_386_GOTOFF = 9;
const R_386_GOTPC = 10;

const PT_NULL = 0;
const PT_LOAD = 1;
const PT_DYNAMIC = 2;
const PT_INTERP = 3;
const PT_NOTE = 4;
const PT_SHLIB = 5;
const PT_PHDR = 6;
const PT_LOOS = 0x6fffffff;
const PT_HIOS = 0x70000000;
const PT_LOPROC = 0x70000000;
const PT_HIPROC = 0x7fffffff;

const PF_X = 0x1;
const PF_W = 0x2;
const PF_R = 0x4;
const PF_MASKOS = 0x00FF0000;
const PF_MASKPROC = 0xFF000000;

const DT_NULL = 0;
const DT_NEEDED = 1;
const DT_PLTRELSZ = 2;
const DT_PLTGOT = 3;
const DT_HASH = 4;
const DT_STRTAB = 5;
const DT_SYMTAB = 6;
const DT_RELA = 7;
const DT_RELASZ = 8;
const DT_RELAENT = 9;
const DT_STRSZ = 10;
const DT_SYMENT = 11;
const DT_INIT = 12;
const DT_FINI = 13;
const DT_SONAME = 14;
const DT_RPATH = 15;
const DT_SYMBOLIC = 16;
const DT_REL = 17;
const DT_RELSZ = 18;
const DT_RELENT = 19;
const DT_PLTREL = 20;
const DT_DEBUG = 21;
const DT_TEXTREL = 22;
const DT_JMPREL = 23;
const DT_LOPROC = 0x70000000;
const DT_HIPROC = 0x7fffffff;

template ELF32_ST_BIND(int i) { const ELF32_ST_BIND = i >> 4; }
template ELF32_ST_TYPE(int i) { const ELF32_ST_TYPE = i & 0xf; }
template ELF32_ST_INFO(int b, int t) { const ELF32_ST_INFO = (b << 4) + (t & 0xf); }
template ELF64_R_SYM(int i) { const ELF64_R_SYM = i >> 32; }
template ELF64_R_TYPE(int i) { const ELF64_R_TYPE = i & 0xffffffffL; }
template ELF64_R_INFO(int s, int t) { const ELF64_R_INFO = (s << 32) + (t & 0xffffffffL); }

const ELF_ENTRYADDY_OFFSET = (EI_NIDENT * ubyte.sizeof) + 2 * Elf64_Half.sizeof + Elf64_Word.sizeof + 4;

/** This structure declares the main elf header. The elf header is
located at the beginning of a loaded binary file, and declares
basic information about the file.
The ElfHeader structure contains the followind fields:
	e_ident: e_ident[] is an array (usually of size 16) which contains basic information
		about the binary file and the system for which it was compiled. The e_ident[] array 
		contains the following fields:
		EI_MAG0, EI_MAG1, EI_MAG2, EI_MAG3: Magic numbers identifying the 
			object file. A proper file should contain the values "x7f", "E",
			"L", and "F" in the EI_MAG0, EI_MAG1, EI_MAG2, and EI_MAG3 
			fields respectively.
		EI_CLASS: This field contains a number identifying the class of the
			object file. The class declares the machine for which the
			object file was compiled. Possible values for this field
			are EICLASSNONE, EICLASS32, and EICLASS64 (see above).
		EI_DATA: This field contains a descriptor of the file encoding,
			thus allowing the system to properly read and manage the
			object file for execution. Possible values are 
			ELFDATA2LSB and ELFDATA2MSB (see above).
		EI_VERSION: This field contains the application or object file's 
			version information.
		EI_OSABI: This field contains a basic descriptor of the type of
			the operating system the object file was compiled for.
			Proper values include "ELFOSABI_SYSV, ELFOSABI_HPUX, and
			ELFOSABI_STANDALONE (see above).
		EI_ABIVERSION:	
		EI_PAD:
	e_type: This field contains information on the object file's type, thus giving the computer
		information on how to handle and execute it. Possible values for e_type are:
			0: No Type
			1: Rellocatable object file
			2: Executable file
			3: Shared object file
			4: Core file
			0xFE00: Environment-specific use
			0xFEFF: Environment-specific use
			0xFF00: Processor-specific use
			0xFFFF: Processor-specific use
	e_machine: This field contains information about the system's architecture for which the 
		object file was compiled. For more information on the values e_machine may take,
		see the documentation provided by your computer's processor manufacturer (e.g. AMD's 64-bit 
		programmer's guide.)
	e_version: This field contains information about the object file's version.
	e_entry: This field contains the address in a system's VIRTUAL memory the object's file _start position
		currently holds. If a system has virtual memory enabled, a program loader can simply jump to this
		location and begin executing the object file.
	e_phoff: This field is an offset, declared in bytes. It declares the number of bytes between the start of the
		object file and the beginning of the file's program header table (see below).
	e_shoff: This field is an offset, declared in bytes. It declares the number of bytes between the start of the
		object file and the beginning of the file's section header table (see below).
	e_flags: This field contains flags which are processor-specific. For more information on these flags, see
		the documentation from the system's processor manufacturer.
	e_ehsize: This field contains the number of bytes in the ELF Header.
	e_phentsize: This field contains the number of bytes used by the object file's program header table.
	e_phnum: This field contains the number of items in the program header table.
	e_shnum: This field contains the number of items in the section header table.
	e_shstrndx: This field contains the index in the section header table where a program loader can find the string table
		containing the names of the sections within the section header table. If there is no such table, this value
		will be SHN_UNDEF (see above).
*/
struct Elf64_Ehdr {
	ubyte e_ident[EI_NIDENT];
	Elf64_Half e_type;	
	Elf64_Half e_machine;	
	Elf64_Word e_version;	
	Elf64_Addr e_entry;	
	Elf64_Off e_phoff;	
	Elf64_Off e_shoff;	
	Elf64_Word e_flags;	
	Elf64_Half e_ehsize;	
	Elf64_Half e_phentsize;	
	Elf64_Half e_phnum;	
	Elf64_Half e_shentsize;	
	Elf64_Half e_shnum;	
	Elf64_Half e_shstrndx;	
}

/** This structure declares the types for a compiled file's program header. The program header is
used by ELF compiled files to declare pieces of information required for execution. The program header
declares, just as an array, a collection of segments which contain information required for program execution.

For a file compiled very simply, the program header may not exist.

This structure is composed of the following members:
	p_type: the type of information contained in an entry in the program header table.
		This variable contains a description of what a specific entry in the program header
		table contains.

	p_flags: this member contains flags, or pieces of information declaring the program header
		entry. The program header entry is, simply, a set of flags, used by a program executor
		when executing a compiled file.
	
	p_offset: this member contains the number of bytes from the beginning of the executable file
		the computer should jump in order to begin reading a specific element in the program header.

	p_vaddr: this member contains the virtual address in a virtual memory scheme where a specific
		entry in a program header begins. In an operating environment whree virtual memory
		is used, the computer can simply jump to this area and begin reading in the information.

	p_paddr: this member contains the physical address in computer memory where a specific
		entry in a program header begins. The system can simply jump to this memory location
		in order to begin reading program header files.
	
	p_filesz: this member contains the number of bytes in a specific segment's physically-written, file
		equivalent. Each section is contained at some point in the compiled file itself. This member
		contains the number of bytes a specific header takes within the compiled file. For some files,
		this value may be 0, depending on how the file was compiled and prepared.

	p_memsz: this member contains the number of bytes in a specific segment's location in memory.
		When loaded, each segment in a program header is loaded into physical memory, preparing for execution.
		This member contains the number of bytes a segment takes up in physical memory.

	p_align: this member declares an alignment operator which allows the system to reconcile p_offset and p_vaddr. 
		That is, it declares how the system translates physical memory addresses to virtual memory addresses.
		This value can either be 0, which indicates there is a 1-1 ratio between physical memory and virtual memory,
		or a positive, power of 2. If the value is non-zero and positive, it should satisfy the condition that
		p_vaddr = p_offset (modulo) p_align.			
*/
struct Elf64_Phdr {
	Elf64_Word p_type; 	
	Elf64_Word p_flags; 	
	Elf64_Off p_offset; 	
	Elf64_Addr p_vaddr; 	
	Elf64_Addr p_paddr; 	
	Elf64_Xword p_filesz;	
	Elf64_Xword p_memsz; 	
	Elf64_Xword p_align; 	
}

/** A compiled file is divided into multiple sections. In order to traverse the file, a program loader must be able to locate
and iterate through all the program sections. The program header table, described by the structure below, creates a specification
for declaring sections within the file. Using this, a program loader can traverse the file logically.

This structure contains the following members:
	
	sh_name: declares the name of a specific section within the file.

	sh_type: declares a type for the section. This value can be an integer, or can be declared using the constants
		with the prefix SHT_ (see above).

	sh_flags: declares flags used by the program to further declare a section. These flags or attributes are 
		one bit in size. They are declared using the constants with the prefix SHF_ (see above).

	sh_addr: this declares the virtual address in a virtual memory scheme for the beginning of a specific file section.
		For systems with enabled virtual memory schemes, the system can jump to this location in order to begin reading
		a section of the compiled file.
	
	sh_offset: this declares the number of bytes dividing the beginning of the section and the beginning of the ELF file.
		A program loader can jump sh_offset number of bytes from the beginning of the ELF file to begin reading a specific
		program section.

	sh_size: this delcares the size of the program section in bytes.

	sh_link: this declares a link to information pertinent to a specific program section. The values are dependent upon the value
		for sh_type.

	sh_info: this declares a generic holder for information about the specific program section. The information contents and form
		are dependent on the sh_type value.

	sh_addralign: this declares an alignment scheme for transferring between virtual and physical memory. This value can be 0, 
		indicating a 1-1 virtual to physical memory scheme, or a positive power of 2.

	sh_entsizde: some sections require additional information, held in a table. Samples include some sections which hold multiple symbols.
		These symboles must be declared in a symbol table. This member declares the size of each entry in that supplemental table.
*/
struct Elf64_Shdr {
	Elf64_Word sh_name; 	/* section name */
	Elf64_Word sh_type; 	/* SHT_... */
	Elf64_Xword sh_flags; 	/* SHF_... */
	Elf64_Addr sh_addr; 	/* virtual address */
	Elf64_Off sh_offset; 	/* file offset */
	Elf64_Xword sh_size; 	/* section size */
	Elf64_Word sh_link; 	/* misc info */
	Elf64_Word sh_info; 	/* misc info */
	Elf64_Xword sh_addralign;/* memory alignment */
	Elf64_Xword sh_entsize; 	/* entry size if table */
}

/** This structure declares information about a standard ELF symbol table. The symboltable contains
information about representations within an executable file. Each symbol within a file must have a definition
so that it can be successfully interpreted. 

This structure contains the following members:

	st_name: the name of any particular symbol in the symbol table
	
	st_info: contains the data type of a symbol and some attribute describing the symbol. See 
		detailed ELF64 specification for more details.

	st_other: Unnused entry.

	st_shndx: each entry in a symbol table is tied to a section of the file.
		This allows the program to define a set of symbols specifically of a section
		in the file. This member contains a reference to a section in the program
		section table to which the symbol entry is tied.

	st_value: contains the interpreted value of the symbol.

	st_size: declares the size of a particular symbol of the symbol table.
*/ 
struct Elf64_Sym {
	Elf64_Word st_name;
	ubyte st_info;
	ubyte st_other;
	Elf64_Half st_shndx;
	Elf64_Addr st_value;
	Elf64_Xword st_size;
}

/** This table contains a list of informative entries which describe how the
executor should tie together symbolic representations in a compiled file
and their literal interpretations, declared in the symbol table.

This section has the following members:

	r_offset: this member contains the number of bytes dividing the beginning of an ELF file
		and the section of the file affected by the symbol table. This is declared to be a
		"relocation," as the executor replaces symbols in a section of the file with their
		literal meanings, declared in the symbol table.

	r_info: this member contains an index in the symbol table which declares the symbols requiring
		"relocation" in the file.
*/
struct Elf64_Rel {
	Elf64_Addr r_offset;
	Elf64_Xword r_info;
}

struct Elf64_Rela {
	Elf64_Addr r_offset;
	Elf64_Xword r_info;
	Elf64_Sxword r_addend;
}

struct Elf64_Dyn {
	Elf64_Sxword d_tag;

	/*
		This is the awesome union.
		AWESOME COMMENT
	*/
	union awesome {
		Elf64_Xword d_val;
		Elf64_Addr d_ptr;
	}

	awesome d_un;
}

public Elf64_Addr _GLOBAL_OFFSET_TABLE_[];

/**
This function takes in the pointer to a name of a section
or symbol and translates it into a useful hash value (long).
This hash value is then returned.
	Params:
		name = A pointer to the value you wish to hash.
	Returns: The hashed value (ulong value)
*/ 
ulong elf64_hash(char *name)
{
	ulong h = 0;
	ulong g;

	while (*name)
	{
		h = (h << 4) + *name++;
		if (g = h & 0xf0000000)
			h ^= g >> 24;
		h &= 0x0fffffff;
	}
	return h;
}

/**
This function takes in a pointer to the beginning of an ELF file
in memory and checks its magic number. If the magic number does not match
an expected value, the ELF file was compiled or loaded improperly.
This method returns a 1 if the magic number is acceptable, or 0 if there is 
problem.
	Params:
		elf_start = A pointer to the beginning of the elf header.
	Returns: int (0 or 1), depending on whether the magic number matches or not.
*/	
int elf64_check_magic(char *elf_start)
{
	if (elf_start[0] == ELFMAG0 &&
		elf_start[1] == ELFMAG1 &&
		elf_start[2] == ELFMAG2 &&
		elf_start[3] == ELFMAG3)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

/**
This method allows the kernel to execute a module loaded using GRUB multiboot. It accepts 
a pointer to the GRUB Multiboot header as well as an integer, indicating the number of the module being loaded.
It then goes through the ELF header of the loaded module, finds the location of the _start section, and
jumps to it, thus beginning execution.

Params:
	moduleNumber = The number of the module the kernel wishes to execute. Integer value.
	mbi = A pointer to the multiboot information structure, allowing this function
		to interperet the module data properly.
*/
void jumpTo(uint moduleNumber, multiboot_info_t* mbi)
{
	// get a pointer to the loaded module.
	module_t* mod = &(cast(module_t*)mbi.mods_addr)[moduleNumber];

	// get the memory address of the module's starting point.
	// also, get a pointer to the module's ELF header.
	void* start = cast(void*)mod.mod_start;
	Elf64_Ehdr* header = cast(Elf64_Ehdr*)start;

	// find all the sections in the module's ELF Section header.
	Elf64_Shdr[] sections = (cast(Elf64_Shdr*)(start + header.e_shoff))[0 .. header.e_shnum];
	Elf64_Shdr* strTable = &sections[header.e_shstrndx];

	// go to the first section in the section header.
	Elf64_Shdr* text = &sections[1];

	// declare a void function which can be called to jump to the memory position of
	// __start().
	void function() entry = cast(void function())(start + text.sh_offset);
	entry();
}
