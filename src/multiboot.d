module multiboot;

import vga;
import util;

/** multiboot.d
	This file declares structures and constants used by GRUB for the multiboot header.
	The multiboot header allows GRUB to load multiple kernels and kernel modules
*/

/**
	License: Copyright (C) 1999, 2001  Free Software Foundation, Inc.

	This program is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the Free Software
	Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA. 
*/

/** This constant declares a universal magic number for the GRUB multiboot header.
The loader passes the kernel a magic number, indicating how it was booted.
If the passed-in value does not match the magic number declared here, the kernel
has not been properly booted using the multiboot header.
*/
const uint MULTIBOOT_HEADER_MAGIC = 0x1BADB002;

/** These constants declare values for multiboot header flags, which tell the
kernel how it should behave once loaded. This bit of code first checks to make
sure that the kernel was compiled using the ELF declaration.
*/
//version(__ELF__){
//	const uint MULTIBOOT_HEADER_FLAGS = 0x00000003;
//} else {
//	const uint MULTIBOOT_HEADER_FLAGS = 0x00010003;
//}

/** This constant declares the magic number passed to the kernel by the GRUB bootloader.
If the kernel finds that its magic number does not match this value, the kernel was not loaded
properly by the GRUB bootloader.
*/
const uint MULTIBOOT_BOOTLOADER_MAGIC = 0x2BADB002;

/** This constant declares the size of the PGOS stack in memory (equivalent to 16 KB) */
const uint STACK_SIZE = 0x4000;

/** C symbol format. HAVE_ASM_USCORE is defined by configure. 
*/
// #ifdef HAVE_ASM_USCORE
// # define EXT_C(sym)                     _ ## sym
// #else
// # define EXT_C(sym)                     sym
// #endif

/** This structure declares the structure for the multiboot header itself. GRUB
passes the multiboot header to the kernel once booted.
For more information on these members and their significances, please read the multiboot specification.
*/
struct multiboot_header_t {
	uint magic;
	uint flags;
	uint checksum;
	uint header_addr;
	uint load_addr;
	uint load_end_addr;
	uint bss_end_addr;
	uint entry_addr;
}

/** Within the multiboot header, GRUB passes the symbol table of the compiled kernel file.
Unfortunately, GRUB cannot natively read ELF64. Therefore, GRUB returns the symbol table in
a.out format. This declares the structure of the a.out symbol table for the kernel.
 */
struct aout_symbol_table_t
{
	uint tabsize;
	uint strsize;
	uint addr;
	uint reserved;
}

/** This declares the structure for the ELF section header table for the compiled kernel file. 
This value is returned to the kernel once booted within the GRUB multiboot header.
*/
struct elf_section_header_table_t
{
	uint num;
	uint size;
	uint addr;
	uint shndx;
}

/** This structure contains information about the multiboot header. It is passed to the kernel for
use during kernel execution.
*/
struct multiboot_info_t
{
	uint flags;
	uint mem_lower;
	uint mem_upper;
	uint boot_device;
	uint cmdline;
	uint mods_count;
	uint mods_addr;

	union
	{
		/// the multiboot header contains both the a.out symbol table and the
		/// ELF section table for the kernel file.
		aout_symbol_table_t aout_sym;
		elf_section_header_table_t elf_sec;
	}

	uint mmap_length;
	uint mmap_addr;
}

/** This structure declares the information contained
within each module loaded by the GRUB mutliboot bootloader.
Most importantly, the mod_start and mod_end variables allow the system
to jump to the modules to begin reading in the modules' ELF header and thus begin
execution.
*/
struct module_t
{
	uint mod_start;
	uint mod_end;
	uint string;
	uint reserved;
}

/** This declares the memory map. The memory map declares the relationship between virtual memory
and physical memory. When the offset is 0, there is no virtual memory, and there is a 1-1 ratio between
virtual memory addresses and physical memory addresses. */
struct memory_map_t
{
	uint size;
	uint base_addr_low;
	uint base_addr_high;
	uint length_low;
	uint length_high;
	uint type;
}

// Tests the multiboot header, prints out relevant mem info, etc
// return: 0 good, -1 bad.
int test_mb_header(uint magic, uint addr)
{
    	// declare a pointer to the multiboot header.
	multiboot_info_t *mbi;

// Make sure that the magic number, passed to the kernel, is a valid GRUB magic number.
	// If it is not, print to the screen that the magic number is invalid and end execution.
	// Invalid magic numbers can indicate that the system was illegally booted, or that the
	// system was booted by a bootloader other than GRUB.
	if(magic != MULTIBOOT_BOOTLOADER_MAGIC)
	{
		kprintfln!("Invalid magic number: 0x{x}")(cast(uint)magic);
		return -1;
	}

	// Set MBI to the address of the Multiboot information structure, passed to the kernel
	// by GRUB.
	mbi = cast(multiboot_info_t*)addr;

	// Print out all the values of the flags presented to the operating system by GRUB.
	kprintfln!("flags = 0x{x}")(cast(uint)mbi.flags);

	// Are mem_* valid
	if(CHECK_FLAG(mbi.flags, 0))
		kprintfln!("mem_lower = {u}KB, mem_upper = {u}KB")(cast(uint)mbi.mem_lower, cast(uint)mbi.mem_upper);

	// Check to make sure the boot device is valid.
	if(CHECK_FLAG(mbi.flags, 1))
		kprintfln!("boot_device = 0x{x}")(cast(uint)mbi.boot_device);

	// Is the command line passed?
	if(CHECK_FLAG(mbi.flags, 2))
		kprintfln!("cmdline = {}")(system.toString(cast(char*)mbi.cmdline));

	// This if statement calls the function CHECK_FLAG on the flags of the GRUB multiboot header.
	// It then checks to make sure the flags are valid (indicating proper, secure booting).
	if(CHECK_FLAG(mbi.flags, 3))
	{
		// print out the number of modules loaded by GRUB, and the physical memory address of the first module in memory.
		kprintfln!("mods_count = {}, mods_addr = 0x{x}")(cast(int)mbi.mods_count, cast(int)mbi.mods_addr);

		module_t* mod;
		int i;

		// Go through all of the modules loaded by GRUB.
		for(i = 0, mod = cast(module_t*)mbi.mods_addr; i < mbi.mods_count; i++, mod++)
		{
			// print out the memory address of the beginning of that module, the address of the end of that module,
			// and the name of that module.
			kprintfln!(" mod_start = 0x{x}, mod_end = 0x{x}, string = {}")(
				cast(uint)mod.mod_start,
				cast(uint)mod.mod_end,
				system.toString(cast(char*)mod.string));
		}

		// Use the jumpTo() method (see below) to execute the first module.
		//jumpTo(0, mbi);
		//return;
	}

	// Bits 4 and 5 are mutually exclusive!
	if(CHECK_FLAG(mbi.flags, 4) && CHECK_FLAG(mbi.flags, 5))
	{
		kprintfln!("Both bits 4 and 5 are set.")();
		return -1;
	}

	// Check to make sure the symbol table of the compiled kernel file is valid.
	if(CHECK_FLAG(mbi.flags, 4))
	{
		// get a pointer to the symbol table, returned by GRUB in the multiboot header.
		aout_symbol_table_t* aout_sym = &(mbi.aout_sym);

		// If it is valid, print out information about the compiled kernel's symbol table.
		kprintfln!("aout_symbol_table: tabsize = 0x{x}, strsize = 0x{x}, addr = 0x{x}")(
			cast(uint)aout_sym.tabsize,
			cast(uint)aout_sym.strsize,
			cast(uint)aout_sym.addr);
	}

	// Check to make sure the section header of the compiled kernel is valid.
	if(CHECK_FLAG(mbi.flags, 5))
	{
		elf_section_header_table_t* elf_sec = &(mbi.elf_sec);

		// If it is valid, print out information about the compiled kernel's section table.
		kprintfln!("elf_sec: num = {u}, size = 0x{x}, addr = 0x{x}, shndx = 0x{x}")(
			cast(uint)elf_sec.num, cast(uint)elf_sec.size,
			cast(uint)elf_sec.addr, cast(uint)elf_sec.shndx);
	}

	// This checks to make sure that the memory map of the bootloader is valid.
	if(CHECK_FLAG(mbi.flags, 6))
	{
		kprintfln!("mmap_addr = 0x{x}, mmap_length = 0x{x}")(cast(uint)mbi.mmap_addr, cast(uint)mbi.mmap_length);

		for(memory_map_t* mmap = cast(memory_map_t*)mbi.mmap_addr;
			cast(uint)mmap < mbi.mmap_addr + mbi.mmap_length;
			mmap = cast(memory_map_t*)(cast(uint)mmap + mmap.size + uint.sizeof))
		{
			kprintfln!(" size = 0x{x}, base_addr = 0x{x}{x}, length = 0x{x}{x}, type = 0x{x}")(
				cast(uint)mmap.size,
				cast(uint)mmap.base_addr_high,
				cast(uint)mmap.base_addr_low,
				cast(uint)mmap.length_high,
				cast(uint)mmap.length_low,
				cast(uint)mmap.type);
		}
	}
	
	return 0;
}