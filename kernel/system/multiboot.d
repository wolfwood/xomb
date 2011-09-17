/* This module handles all of the multiboot
 * things that we could ever want.
 */
module kernel.system.multiboot;

import kernel.core.error;
import kernel.core.kprintf;
import kernel.core.util;
import kernel.system.definitions;
import kernel.system.info;

import user.types;

/* These two magic numbers are
 * defined in the multiboot spec, we use them
 * to verify that our environment is sane.
 */
const MULTIBOOT_HEADER_MAGIC = 0x1BADB002;
const MULTIBOOT_BOOTLOADER_MAGIC = 0x2BADB002;

/* this function tests the nth bit of flags
 * and returns true if it is 1 and false if it is 0
 */
bool checkFlag(ulong flags,int n) {
	// shift a one over n bits and then logically and, then cast to bool
	// ie n		 = 2
	// ie flags = 0110
	//		1 <<n = 0100
	// and-ed	 = 0100
	return ((flags) & (1 << (n))) != 0;
}

/* The symbol table for a.out. */
struct aout_symbol_table {
	uint tabsize;
	uint strsize;
	uint addr;
	uint reserved;
}

/* The section header table for ELF. */
struct elf_section_header_table {
	uint num;
	uint size;
	uint addr;
	uint shndx;
}

union symbol_tables {
	aout_symbol_table aout_sym;
	elf_section_header_table elf_sec;
}

// Sanity check
static assert(symbol_tables.sizeof == 16);

struct multiboot_info {
	uint flags;
	uint mem_lower;
	uint mem_upper;
	uint boot_device;
	uint cmdline;
	uint mods_count;
	uint mods_addr;
	symbol_tables syms;
	uint mmap_length;
	uint mmap_addr;
	uint drives_length;
	uint drives_addr;
	uint config_table;
	uint boot_loader_name;
	uint apm_table;
	uint vbe_control_info;
	uint vbe_mode_info;
	ushort vbe_mode;
	ushort vbe_interface_seg;
	ushort vbe_interface_off;
	ushort vbe_interface_len;
}

// Sanity check
static assert(multiboot_info.sizeof == 88);

//since module is a d reserved word...
struct multi_module {
	uint mod_start;
	uint mod_end;
	uint string;
	uint reserved;
}

struct memory_map {
	uint size;
	uint base_addr_low;
	uint base_addr_high;
	uint length_low;
	uint length_high;
	uint type;
}

struct drive_info {
	uint size;

	ubyte drive_number;
	ubyte drive_mode;
	ushort drive_cylinders;
	ubyte drive_heads;
	ubyte drive_sectors;

	// The rest are ports
	ushort ports;
}

// this function takes the information that the boot loader gives us,
// and fills out the System struct. This way, none of the rest of
// our code needs to know anything about multiboot, and if we made
// it use a different spec, everything else wouldn't break!
ErrorVal verifyBootInformation(int id, void *data) {

	//check if our header magic is correct
	if(id != MULTIBOOT_BOOTLOADER_MAGIC) { return ErrorVal.Fail; }

	multiboot_info *info = cast(multiboot_info *)(data);

	//kprintfln!("flags: 0x{x}")(info.flags);

	//is mem_* valid?
	if(!checkFlag(info.flags, 0)) {
		return ErrorVal.Fail;
	}

	//kprintfln!("wh")();

	//is our boot device valid
	if(!checkFlag(info.flags, 1)) {
		return ErrorVal.Fail;
	}

	//kprintfln!("wha")();

	//is command line passed?
	if(!checkFlag(info.flags, 2)) {
		return ErrorVal.Fail;
	}else{
		char* cmd = (cast(char*)info.cmdline);
		uint len = strlen(cmd);

		System.cmdlineStorage[0..len] = cmd[0..len];
		System.cmdline = System.cmdlineStorage[0..len];
	}

	//are the modules valid?
	if(checkFlag(info.flags, 3)) {
		// some variables used in the next loop. mod
		// will point at the current module, and we
		// loop until mod_count modules have been inspected
		multi_module *mod = cast(multi_module *)(info.mods_addr);
		int mod_count = info.mods_count;

		for(int i = 0; i < mod_count && i < System.moduleInfo.length; i++, mod++) {
			System.moduleInfo[i].start = cast(PhysicalAddress)(mod.mod_start);
			System.moduleInfo[i].length = cast(uint)(mod.mod_end - mod.mod_start);

			int len = strlen(cast(char *)mod.string);
			if (len > System.moduleInfo[i].nameSpace.length) {
				len = System.moduleInfo[i].nameSpace.length;
			}
			System.moduleInfo[i].nameSpace[0 .. len] = (cast(char *)(mod.string))[0 .. len];
			System.moduleInfo[i].name = System.moduleInfo[i].nameSpace[0 .. len];

			//kprintfln!("module {}: start:{} length:{} name:{}")(i, System.moduleInfo[i].start, System.moduleInfo[i].length, System.moduleInfo[i].name[0..len]);
			System.numModules++;
		}
	}

	// Memory Map Fields
	if (checkFlag(info.flags, 6)) {
		// Cast the memory map structure, so we can read
		memory_map* mmap = cast(memory_map*)(info.mmap_addr);

		// I do it in this weird way because it seems like the specification
		// wants to not assume the size of any entry.
		for (uint i=0; i < info.mmap_length; ) {
			// Compute the true values from the table
			ulong baseAddr = cast(ulong)mmap.base_addr_low | (cast(ulong)mmap.base_addr_high << 32);
			ulong length = cast(ulong)mmap.length_low | (cast(ulong)mmap.length_high << 32);

			// Is this available ram?
			if (mmap.type == 1) {
				// This shows System RAM that can be used
				ulong endAddr = baseAddr + length;
				if (System.memory.length < endAddr) {
					System.memory.length = endAddr;
					//kprintfln!("Memory Length Update: {x}")(System.memory.length);
				}
			}
			else {
				// This is a reserved region
				if (System.numRegions < System.regionInfo.length) {
					System.regionInfo[System.numRegions].start = cast(PhysicalAddress)baseAddr;
					System.regionInfo[System.numRegions].length = length;
					System.numRegions++;
				}
			}

			// Advance to the next entry (Note: the size field is implied)
			i += mmap.size + 4;
			mmap = cast(memory_map*)((cast(ubyte*)mmap) + mmap.size + 4);
		}
	}

	// bit 4 and bit 5 are mutually exculsive

	// flag 4 checks to see if a.out is valid.
	// we don't use a.out, so we don't care!

	// flag 5 checks to see if elf section table is valid.
	// we don't use it, so we don't care!

	if((checkFlag(info.flags, 4)) && (checkFlag(info.flags, 5))) {
		return ErrorVal.Fail;
	}
	//kprintfln!("HEY {}")(System.numDisks);

	// Drive Information
	if (checkFlag(info.flags, 7)) {
		// We have drive information, so get it.

		// Cast the memory map structure, so we can read
		drive_info* dinfo = cast(drive_info*)(info.drives_addr);

		// I do it in this weird way because the specification
		// defines an arbitrary number of entries for drive ports.
		for (uint i=0; i < info.drives_length; ) {
			with(System.diskInfo[System.numDisks]) {
				// Identifier
				number = dinfo.drive_number;

				// Configuration
				heads = dinfo.drive_heads;
				cylinders = dinfo.drive_cylinders;
				sectors = dinfo.drive_sectors;

				// Ports (determined by the size of the structure)
				numPorts = dinfo.size - 10;
				numPorts /= 2;

				// Allow no more than the amount we can statically store
				if (numPorts > ports.length) {
					numPorts = ports.length;
				}
				//kprintfln!("Drive: {} Heads: {} Cyl: {} Sectors: {} Ports: {}")(number, heads, cylinders, sectors, numPorts);

				// Copy the information
				ushort* curPort = &dinfo.ports;
				for (uint j = 0; j < numPorts; j++) {
					ports[j] = *curPort;
					curPort++;
				}
			}

			// Go to the next disk entry.
			System.numDisks++;

			if (System.numDisks >= System.diskInfo.length) {
				break;
			}

			// Advance to the next entry (Note: the size field is implied)
			i += dinfo.size + 4;
			dinfo = cast(drive_info*)((cast(ubyte*)dinfo) + dinfo.size + 4);
		}
	}

	//kprintfln!("DONE")();

	//wow, we made it!
	return ErrorVal.Success;
}
