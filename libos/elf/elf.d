/*
 * elf.d
 *
 * This module implements functions related to reading ELF headers.
 *
 */

module libos.elf.elf;

import libos.elf.segment;

//import kernel.core.kprint;

struct Elf {
static:

	alias void* elf64_addr;	   // size 8
	alias ulong elf64_off;	   // size 8
	alias ushort elf64_half;   // size 2
	alias uint elf64_word;	   // size 4
	alias int elf64_sword;	   // size 4
	alias ulong elf64_xword;   // size 8
	alias long elf64_sxword;   // size 8


	const et_none = 0;
	const et_rel = 1;
	const et_exec = 2;
	const et_dyn = 3;
	const et_core = 4;
	const et_loos = 0xfe00;
	const et_hios = 0xfeff;
	const et_loproc = 0xff00;
	const et_hiproc = 0xffff;

	/** these values declare types of architectures, used in the e_machine field of the elf header (see below).
	  these valeus represent common types of architectures, including i386 (3), sun's sparc (2), and mips (8).
	 */
	const em_none = 0;
	const em_m32 = 1;
	const em_sparc = 2;
	const em_386 = 3;
	const em_68k = 4;
	const em_88k = 5;
	const em_860 = 7;
	const em_mips = 8;
	const ev_none = 0;
	const ev_current = 1;

	/** these constant values declare the index location of the items in the
	  e_ident[] array (declared in the elf64_ehhdr structure, shown below).
	  they correspond to basic information about the file. for example, e_mag0,
	  or the first magic number, is located at byte 0 of the e_ident[] array,
	  and declares a number to identify the binary file when loaded.
	 */
	const ei_mag0 = 0;
	const ei_mag1 = 1;
	const ei_mag2 = 2;
	const ei_mag3 = 3;
	const ei_class = 4;
	const ei_data = 5;
	const ei_version = 6;
	const ei_osabi = 7;
	const ei_abiversion = 8;
	const ei_pad = 9;

	/** ei_nident declares the size, in items, of the e_ident[] array.
	  for a standard 64-bit compiled elf object file, the e_ident[] array
	  has 16 items.
	 */
	const ei_nident = 16;
	const elfosabi_sysv = 0;
	const elfosabi_hpux = 1;
	const elfosabi_standalone = 255;

	const elfmag0 = 0x7f;
	const elfmag1 = 0x45;
	const elfmag2 = 0x4c;
	const elfmag3 = 0x46;

	/** these constant variables declare possible values for the ei_class
	  member of the e_ident[] array. they identify the object file as
	  being compiled on a 32-bit machine (elfclass32), a 64-bit machine
	  (elfclass64), or being invalid (elfclassnone).
	 */
	const elfclassnone = 0;
	const elfclass32 = 1;
	const elfclass64 = 2;
	const elfdatanone = 0;
	const elfdata2lsb = 1;
	const elfdata2msb = 2;
	const shn_undef = 0;
	const shn_loproc = 0xff00;
	const shn_hiproc = 0xff1f;
	const shn_loos = 0xff20;
	const shn_hios = 0xff3f;
	const shn_abs = 0xfff1;
	const shn_common = 0xfff2;

	/** these constants declare various types for a section in a section table.
	  for more information on their meaning, see their in-depth descriptions in the
	  elf64 header declaration. */
	const sht_null = 0;
	const sht_progbits = 1;
	const sht_symtab = 2;
	const sht_strtab = 3;
	const sht_rela = 4;
	const sht_hash = 5;
	const sht_dynamic = 6;
	const sht_note = 7;
	const sht_nobits = 8;
	const sht_rel = 9;
	const sht_shlib = 10;
	const sht_dynsym = 11;
	const sht_loos = 0x60000000;
	const sht_hios = 0x6fffffff;
	const sht_loproc = 0x70000000;
	const sht_hiproc = 0x7fffffff;
	const sht_x86_64_unwind = 0x70000001;

	/** these constants declare possible values for the section header's flags member. these values are declared below:
	shf_write: indicates that a section contains information that is directly writable during execution.
	shf_alloc: indicates that a specific section must be allocated memory during execution. some sections
	do not reside in memory during execution. in these examples, this flag would not be set.

	shf_execinstr: indicates that a specific section contains information that can be directly executed by a
	processor (e.g. it contains machine instructions).
	 */
	const shf_write = 0x1;
	const shf_alloc = 0x2;
	const shf_execinstr = 0x4;
	const shf_x86_64_large = 0x10000000;
	const shf_maskos = 0x0f000000;
	const shf_maskproc = 0xf0000000;
	const stb_local = 0;
	const stb_global = 1;
	const stb_weak = 2;
	const stb_loos = 10;
	const stb_hios = 12;
	const stb_loproc = 13;
	const stb_hiproc = 15;

	const stt_notype = 0;
	const stt_object = 1;
	const stt_func = 2;
	const stt_section = 3;
	const stt_file = 4;
	const stt_loos = 10;
	const stt_hios = 12;
	const stt_loproc = 13;
	const stt_hiproc = 15;

	const r_386_none = 0;
	const r_386_32 = 1;
	const r_386_pc32 = 2;
	const r_386_got32 = 3;
	const r_386_plt32 = 4;
	const r_386_copy = 5;
	const r_386_glob_dat = 6;
	const r_386_jmp_slot = 7;
	const r_386_relative = 8;
	const r_386_gotoff = 9;
	const r_386_gotpc = 10;

	const pt_null = 0;
	const pt_load = 1;
	const pt_dynamic = 2;
	const pt_interp = 3;
	const pt_note = 4;
	const pt_shlib = 5;
	const pt_phdr = 6;
	const pt_loos = 0x6fffffff;
	const pt_hios = 0x70000000;
	const pt_loproc = 0x70000000;
	const pt_hiproc = 0x7fffffff;

	const pf_x = 0x1;
	const pf_w = 0x2;
	const pf_r = 0x4;
	const pf_maskos = 0x00ff0000;
	const pf_maskproc = 0xff000000;

	const dt_null = 0;
	const dt_needed = 1;
	const dt_pltrelsz = 2;
	const dt_pltgot = 3;
	const dt_hash = 4;
	const dt_strtab = 5;
	const dt_symtab = 6;
	const dt_rela = 7;
	const dt_relasz = 8;
	const dt_relaent = 9;
	const dt_strsz = 10;
	const dt_syment = 11;
	const dt_init = 12;
	const dt_fini = 13;
	const dt_soname = 14;
	const dt_rpath = 15;
	const dt_symbolic = 16;
	const dt_rel = 17;
	const dt_relsz = 18;
	const dt_relent = 19;
	const dt_pltrel = 20;
	const dt_debug = 21;
	const dt_textrel = 22;
	const dt_jmprel = 23;
	const dt_loproc = 0x70000000;
	const dt_hiproc = 0x7fffffff;

	template elf32_st_bind(int i) { const elf32_st_bind = i >> 4; }
	template elf32_st_type(int i) { const elf32_st_type = i & 0xf; }
	template elf32_st_info(int b, int t) { const elf32_st_info = (b << 4) + (t & 0xf); }
	template elf64_r_sym(int i) { const elf64_r_sym = i >> 32; }
	template elf64_r_type(int i) { const elf64_r_type = i & 0xffffffffL; }
	template elf64_r_info(int s, int t) { const elf64_r_info = (s << 32) + (t & 0xffffffffL); }

	const elf_entryaddy_offset = (ei_nident * ubyte.sizeof) + 2 * elf64_half.sizeof + elf64_word.sizeof + 4;

	/** this structure declares the main elf header. the elf header is
	  located at the beginning of a loaded binary file, and declares
	  basic information about the file.
	  the elfheader structure contains the followind fields:

	e_ident: e_ident[] is an array (usually of size 16) which contains basic information
		about the binary file and the system for which it was compiled. the e_ident[] array
		contains the following fields:
		ei_mag0, ei_mag1, ei_mag2, ei_mag3: magic numbers identifying the
		object file. a proper file should contain the values "x7f", "e",
		"l", and "f" in the ei_mag0, ei_mag1, ei_mag2, and ei_mag3
		fields respectively.
	ei_class: this field contains a number identifying the class of the
		object file. the class declares the machine for which the
		object file was compiled. possible values for this field
		are eiclassnone, eiclass32, and eiclass64 (see above).
	ei_data: this field contains a descriptor of the file encoding,
		thus allowing the system to properly read and manage the
		object file for execution. possible values are
		elfdata2lsb and elfdata2msb (see above).
	ei_version: this field contains the application or object file's
		version information.
	ei_osabi: this field contains a basic descriptor of the type of
		the operating system the object file was compiled for.
		proper values include "elfosabi_sysv, elfosabi_hpux, and
		elfosabi_standalone (see above).
	ei_abiversion:
	ei_pad:
	e_type: this field contains information on the object file's type, thus giving the computer
		information on how to handle and execute it. possible values for e_type are:
		0: no type
		1: rellocatable object file
		2: executable file
		3: shared object file
		4: core file
		0xfe00: environment-specific use
		0xfeff: environment-specific use
		0xff00: processor-specific use
		0xffff: processor-specific use
	e_machine: this field contains information about the system's architecture for which the
		object file was compiled. for more information on the values e_machine may take,
		see the documentation provided by your computer's processor manufacturer (e.g. amd's 64-bit
		programmer's guide.)
	e_version: this field contains information about the object file's version.
	e_entry: this field contains the address in a system's virtual memory the object's file _start position
		currently holds. if a system has virtual memory enabled, a program loader can simply jump to this
		location and begin executing the object file.
	e_phoff: this field is an offset, declared in bytes. it declares the number of bytes between the start of the
		object file and the beginning of the file's program header table (see below).
	e_shoff: this field is an offset, declared in bytes. it declares the number of bytes between the start of the
		object file and the beginning of the file's section header table (see below).
	e_flags: this field contains flags which are processor-specific. for more information on these flags, see
		the documentation from the system's processor manufacturer.
	e_ehsize: this field contains the number of bytes in the elf header.
	e_phentsize: this field contains the number of bytes used by the object file's program header table.
	e_phnum: this field contains the number of items in the program header table.
	e_shnum: this field contains the number of items in the section header table.
	e_shstrndx: this field contains the index in the section header table where a program loader can find the string table
		containing the names of the sections within the section header table. if there is no such table, this value
		will be shn_undef (see above).
	 */
	struct elf64_ehdr {
		ubyte e_ident[ei_nident];
		elf64_half e_type;
		elf64_half e_machine;
		elf64_word e_version;
		elf64_addr e_entry;
		elf64_off e_phoff;
		elf64_off e_shoff;
		elf64_word e_flags;
		elf64_half e_ehsize;
		elf64_half e_phentsize;
		elf64_half e_phnum;
		elf64_half e_shentsize;
		elf64_half e_shnum;
		elf64_half e_shstrndx;
	}

	/** this structure declares the types for a compiled file's program header. the program header is
	  used by elf compiled files to declare pieces of information required for execution. the program header
	  declares, just as an array, a collection of segments which contain information required for program execution.
	  for a file compiled very simply, the program header may not exist.

	  this structure is composed of the following members:

	e_type: the type of information contained in an entry in the program header table.
		this variable contains a description of what a specific entry in the program header
		table contains.
	p_flags: this member contains flags, or pieces of information declaring the program header
		entry. the program header entry is, simply, a set of flags, used by a program executor
		when executing a compiled file.
	p_offset: this member contains the number of bytes from the beginning of the executable file
		the computer should jump in order to begin reading a specific element in the program header.
	p_vaddr: this member contains the virtual address in a virtual memory scheme where a specific
		entry in a program header begins. in an operating environment whree virtual memory
		is used, the computer can simply jump to this area and begin reading in the information.
	p_paddr: this member contains the physical address in computer memory where a specific
		entry in a program header begins. the system can simply jump to this memory location
		in order to begin reading program header files.
	p_filesz: this member contains the number of bytes in a specific segment's physically-written, file
		equivalent. each section is contained at some point in the compiled file itself. this member
		contains the number of bytes a specific header takes within the compiled file. for some files,
		this value may be 0, depending on how the file was compiled and prepared.
	p_memsz: this member contains the number of bytes in a specific segment's location in memory.
		when loaded, each segment in a program header is loaded into physical memory, preparing for execution.
		this member contains the number of bytes a segment takes up in physical memory.
	p_align: this member declares an alignment operator which allows the system to reconcile p_offset and p_vaddr.
		that is, it declares how the system translates physical memory addresses to virtual memory addresses.
		this value can either be 0, which indicates there is a 1-1 ratio between physical memory and virtual memory,
		or a positive, power of 2. if the value is non-zero and positive, it should satisfy the condition that
		p_vaddr = p_offset (modulo) p_align.
	 */
	struct elf64_phdr {
		elf64_word p_type;
		elf64_word p_flags;
		elf64_off p_offset;
		elf64_addr p_vaddr;
		elf64_addr p_paddr;
		elf64_xword p_filesz;
		elf64_xword p_memsz;
		elf64_xword p_align;
	}

	/** a compiled file is divided into multiple sections. in order to traverse the file, a program loader must be able to locate
	  and iterate through all the program sections. the program header table, described by the structure below, creates a specification
	  for declaring sections within the file. using this, a program loader can traverse the file logically.
	  this structure contains the following members:

	sh_name: declares the name of a specific section within the file.
	sh_type: declares a type for the section. this value can be an integer, or can be declared using the constants
		with the prefix sht_ (see above).
	sh_flags: declares flags used by the program to further declare a section. these flags or attributes are
		one bit in size. they are declared using the constants with the prefix shf_ (see above).
	sh_addr: this declares the virtual address in a virtual memory scheme for the beginning of a specific file section.
		for systems with enabled virtual memory schemes, the system can jump to this location in order to begin reading
		a section of the compiled file.
	sh_offset: this declares the number of bytes dividing the beginning of the section and the beginning of the elf file.
		a program loader can jump sh_offset number of bytes from the beginning of the elf file to begin reading a specific
		program section.
	sh_size: this delcares the size of the program section in bytes.
	sh_link: this declares a link to information pertinent to a specific program section. the values are dependent upon the value
		for sh_type.
	sh_info: this declares a generic holder for information about the specific program section. the information contents and form
		are dependent on the sh_type value.
	sh_addralign: this declares an alignment scheme for transferring between virtual and physical memory. this value can be 0,
		indicating a 1-1 virtual to physical memory scheme, or a positive power of 2.
	sh_entsizde: some sections require additional information, held in a table. samples include some sections which hold multiple symbols.
		these symboles must be declared in a symbol table. this member declares the size of each entry in that supplemental table.
	 */
	struct elf64_shdr {
		elf64_word sh_name; 	/* section name */
		elf64_word sh_type; 	/* sht_... */
		elf64_xword sh_flags; 	/* shf_... */
		elf64_addr sh_addr; 	/* virtual address */
		elf64_off sh_offset; 	/* file offset */
		elf64_xword sh_size; 	/* section size */
		elf64_word sh_link; 	/* misc info */
		elf64_word sh_info; 	/* misc info */
		elf64_xword sh_addralign;/* memory alignment */
		elf64_xword sh_entsize; 	/* entry size if table */
	}

	/** this structure declares information about a standard elf symbol table. the symboltable contains
	  information about representations within an executable file. each symbol within a file must have a definition
	  so that it can be successfully interpreted.
	  this structure contains the following members:

	st_name: the name of any particular symbol in the symbol table
	st_info: contains the data type of a symbol and some attribute describing the symbol. see
		detailed elf64 specification for more details.
	st_other: unnused entry.
	st_shndx: each entry in a symbol table is tied to a section of the file.
		this allows the program to define a set of symbols specifically of a section
		in the file. this member contains a reference to a section in the program
		section table to which the symbol entry is tied.
	st_value: contains the interpreted value of the symbol.
	st_size: declares the size of a particular symbol of the symbol table.
	 */
	struct elf64_sym {
		elf64_word st_name;
		ubyte st_info;
		ubyte st_other;
		elf64_half st_shndx;
		elf64_addr st_value;
		elf64_xword st_size;
	}

	/** this table contains a list of informative entries which describe how the
	  executor should tie together symbolic representations in a compiled file
	  and their literal interpretations, declared in the symbol table.
	  this section has the following members:

	r_offset: this member contains the number of bytes dividing the beginning of an elf file
		and the section of the file affected by the symbol table. this is declared to be a
		"relocation," as the executor replaces symbols in a section of the file with their
		literal meanings, declared in the symbol table.
	r_info: this member contains an index in the symbol table which declares the symbols requiring
		"relocation" in the file.
	 */
	struct elf64_rel {
		elf64_addr r_offset;
		elf64_xword r_info;
	}

	struct elf64_rela {
		elf64_addr r_offset;
		elf64_xword r_info;
		elf64_sxword r_addend;
	}

	struct elf64_dyn {
		elf64_sxword d_tag;

		/*
		   this is the awesome union.
		   awesome comment
		 */
		union awesome {
			elf64_xword d_val;
			elf64_addr d_ptr;
		}

		awesome d_un;
	}

	public elf64_addr _global_offset_table_[];

	/**
	  this function takes in the pointer to a name of a section
	  or symbol and translates it into a useful hash value (long).
	  this hash value is then returned.

	params:

	  name = a pointer to the value you wish to hash.
		returns: the hashed value (ulong value)
	 */
	ulong elf64_hash(char *name) {
		ulong h = 0;
		ulong g;
		while (*name) {
			h = (h << 4) + *name++;
			if ((g = h & 0xf0000000) != 0) {
				h ^= g >> 24;
			}
			h &= 0x0fffffff;
		}
		return h;
	}

	/**
	  this function takes in a pointer to the beginning of an elf file
	  in memory and checks its magic number. if the magic number does not match
	  an expected value, the elf file was compiled or loaded improperly.
	  this method returns a 1 if the magic number is acceptable, or 0 if there is
	  problem.

	params:

		elf_start = a pointer to the beginning of the elf header.
			returns: int (0 or 1), depending on whether the magic number matches or not.
	*/
	bool isValid(ubyte* address) {
		//kprintfln!("ELF header: {x} {x} {x} {x}...")(address[0], address[1], address[2], address[3]);
		if (address[0] == elfmag0 &&
			address[1] == elfmag1 &&
			address[2] == elfmag2 &&
			address[3] == elfmag3) {
			return true;
		}
		return false;
	}

	// will return the offset to the bss section or null.  it will fill the variables.  it will return true on success.
	bool fillbssinfo(void* address, out void* bssaddress, out uint length) {
	/*	bssaddress = null;
		length = 0;

		elf64_ehdr* header = cast(elf64_ehdr*)address;

		// the string table must be defined
		if (header.e_shstrndx == shn_undef) { return false; }

		// we need to get the section containing the 'bss'

		elf64_shdr[] sections = (cast(elf64_shdr*)(address + header.e_shoff))[0 .. header.e_shnum];
		elf64_shdr* strtable = &sections[header.e_shstrndx];

		// look at all of the sections until (and if) we find the .bss section

		// get the address of the string table data
		ubyte* strtableaddr = cast(ubyte*)(address + strtable.sh_offset);

		foreach(section; sections) {
			// hopefully counter security concerns
			if (section.sh_name > strtable.sh_size) {
				continue;
			}

			ubyte* secttext = strtableaddr + section.sh_name;

			if (secttext[0] == '.' && secttext[1] == 'b' && secttext[2] == 's' && secttext[3] == 's') {
				// found it
				bssaddress = cast(void*)section.sh_offset;
				length = section.sh_size;
				return true;
			}
		}*/

		return false;
	}

	/**
	  this method allows the kernel to execute a module loaded using grub multiboot. it accepts
	  a pointer to the grub multiboot header as well as an integer, indicating the number of the module being loaded.
	  it then goes through the elf header of the loaded module, finds the location of the _start section, and
	  jumps to it, thus beginning execution.

	params:

	modulenumber = the number of the module the kernel wishes to execute. integer value.
	mbi = a pointer to the multiboot information structure, allowing this function
		to interperet the module data properly.
	*/

	// gets the entry point at the elf header located at address
	void* getentry(void* address) {
/*		elf64_ehdr* header = cast(elf64_ehdr*)address;

		// find all the sections in the module's elf section header.
		elf64_shdr[] sections = (cast(elf64_shdr*)(address + header.e_shoff))[0 .. header.e_shnum];
		elf64_shdr* strtable = &sections[header.e_shstrndx];

		// go to the first section in the section header.
		elf64_shdr* text = &sections[1];

		// declare a void function which can be called to jump to the memory position of
		// __start().
		return cast(void*)text.sh_offset;*/
		return (cast(void*)(cast(elf64_ehdr*)address).e_entry);
	}

	void* getphysaddr(void* address) {
		elf64_ehdr* header = cast(elf64_ehdr*)address;
		elf64_phdr* load = cast(elf64_phdr*)(address + header.e_phoff);
		return cast(void*)load.p_paddr;
	}

	void* getvirtaddr(void* address) {
		elf64_ehdr* header = cast(elf64_ehdr*)address;
		elf64_phdr* load = cast(elf64_phdr*)(address + header.e_phoff);
		return cast(void*)load.p_vaddr;
	}

	ulong getoffset(void* address) {
		elf64_ehdr* header = cast(elf64_ehdr*)address;

		// find all the sections in the module's elf section header.
		//elf64_shdr[] sections = (cast(elf64_shdr*)(address + header.e_shoff))[0 .. header.e_shnum];
		//elf64_shdr* strtable = &sections[header.e_shstrndx];

		// go to the first section in the section header.
		elf64_phdr* load = cast(elf64_phdr*)(address + header.e_phoff);

		//kprintfln!("text phoff: {x} ptr: {x}")(header.e_phoff, load);
		// declare a void function which can be called to jump to the memory position of
		// __start();;
		return cast(ulong)load.p_offset;
	}

	ulong segmentCount(void* address) {
		elf64_ehdr* header = cast(elf64_ehdr*)address;
		return header.e_phnum;
	}

	Segment segment(void* address, uint index) {
		elf64_ehdr* header = cast(elf64_ehdr*)address;

		elf64_phdr* prog = cast(elf64_phdr*)(address + header.e_phoff + (elf64_phdr.sizeof * index));

		Segment s;
		s.physAddress = cast(void*)prog.p_paddr;
		s.virtAddress = cast(void*)prog.p_vaddr;

		s.offset = prog.p_offset;

		s.length = prog.p_memsz;

		s.writeable = true;
		s.executable = true;

		return s;
	}
}
