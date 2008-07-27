module kernel.mem.vmem_structs;

import kernel.core.util;



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