module kernel.mem.regions;

import kernel.core.util;
import kernel.mem.vmem;
import kernel.core.multiboot;

import kernel.dev.vga;

struct mem_region 
{
	ubyte* virtual_start;
	ubyte* physical_start;
	ulong length;
}


struct global_mem_region {

	// the regions mapped after physical memory
	// typically mapped bios regions
	mem_region kernel_mapped;
	
	// the kernel code and pages owned by it
	mem_region kernel;

	// the mapped RAM
	mem_region system_memory;

	// bios and legacy regions
	mem_region bios_data;
	mem_region extended_bios_data;
	mem_region extended_memory;
	mem_region device_maps;

	// APIC register space (part of kernel_mapped)
	mem_region apic_register;
} 

// Global mem map regions live here :)
global_mem_region global_mem_regions;

void initBIOSRegions(memory_map_t[] mmap)
{
	foreach(int z, map; mmap)
	{
		// For sanity...
		ulong base_addr = map.base_addr_high << 32;
		base_addr += map.base_addr_low;
		
		ulong mem_length = map.length_high << 32;
		mem_length += map.length_low;

		//kprintfln!(" size = 0x{x}, base_addr = 0x{x}, length = 0x{x}, type = 0x{x}")(
			//cast(uint)map.size_of,
			//base_addr,
			//mem_length,
			//cast(uint)map.type);

		switch(z) {
		case 0:

			// ignore system memory region
			// pMem takes care of this

			break;
		case 1:
			global_mem_regions.bios_data.physical_start = cast(ubyte*)base_addr;
			global_mem_regions.bios_data.length = mem_length;
			break;
		case 2:
			global_mem_regions.extended_bios_data.physical_start = cast(ubyte*)base_addr;
			global_mem_regions.extended_bios_data.length = mem_length;
			break;
		case 3:
			global_mem_regions.extended_memory.physical_start = cast(ubyte*)base_addr;
			global_mem_regions.extended_memory.length = mem_length;
			break;
		case 4: 
			global_mem_regions.device_maps.physical_start = cast(ubyte*)base_addr;
			global_mem_regions.device_maps.length = mem_length;
			break;
		default:
			break;
		}

	}
}

void mapBIOSRegions()
{
	vMem.mapRange(global_mem_regions.bios_data.physical_start, 
				global_mem_regions.bios_data.length, 
				global_mem_regions.bios_data.virtual_start);

	vMem.mapRange(global_mem_regions.extended_bios_data.physical_start, 
				global_mem_regions.extended_bios_data.length, 
				global_mem_regions.extended_bios_data.virtual_start);

	vMem.mapRange(global_mem_regions.extended_memory.physical_start, 
				global_mem_regions.extended_memory.length, 
				global_mem_regions.extended_memory.virtual_start);

	vMem.mapRange(global_mem_regions.device_maps.physical_start, 
				global_mem_regions.device_maps.length, 
				global_mem_regions.device_maps.virtual_start);
}
