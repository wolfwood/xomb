module multiboot;

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
