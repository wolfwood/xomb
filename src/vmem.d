/* vmem.d - virtual memory stuffs
 *
 * So far just the page fault handler
 */


/* Handle faults -- the fault handler
 * This should handle everything when a page fault
 * occurs.
 */


import vga;
import util;
import multiboot;

static import idt;

void handle_faults(idt.interrupt_stack* ir_stack) 
{
	// First we need to determine why the page fault happened
	// This ulong will contain the address of the section of memory being faulted on
	ulong addr;
	// This is the dirty asm that gets the address for us...
	asm { "mov %%cr2, %%rax" ::: "rax"; "movq %%rax, %0" :: "m" addr; }
	// And this is a print to show us whats going on

	// Page fault error code is as follows (page 225 of AMD System docs):
	// Bit 0 = P bit - set to 0 if fault was due to page not present, 1 otherwise
	// Bit 1 = R/W bit - 0 for read, 1 for write fault
	// Bit 2 = U/S bit - 0 if fault in supervisor mode, 1 if usermode
	// Bit 3 = RSV bit - 1 if processor tried to read from a reserved field in PTE
	// Bit 4 = I/D bit - 1 if instruction fetch, otherwise 0
	// The rest of the error code byte is considered reserved

	// The easiest way to find if a bit is set is by & it with a mask and check for ! 0

	kprintfln("\n Page fault. Code = %d, IP = 0x%x, VA = 0x%x, RBP = 0x%x\n", ir_stack.err_code, ir_stack.rip, addr, ir_stack.rbp);

	if((ir_stack.err_code & 1) == 0) 
	{
		kprintfln("Error due to page not present!");

		if((ir_stack.err_code & 2) != 0)
		{
			kprintfln("Error due to write fault.");
		}
		else
		{
			kprintfln("Error due to read fault.");
		}

		if((ir_stack.err_code & 4) != 0)
		{
			kprintfln("Error occurred in usermode.");
			// In this case we need to send a signal to the libOS handler
		}
		else
		{
			kprintfln("Error occurred in supervised mode.");
			// In this case we're super concerned and need to handle the fault
		}

		if((ir_stack.err_code & 8) != 0)
		{
			kprintfln("Tried to read from a reserved field in PTE!");
		}
	
		if((ir_stack.err_code & 16) != 0)
		{
			kprintfln("Instruction fetch error!");
		}
	}
}

uint CHECK_FLAG(uint flags, uint bit)
{
	return ((flags) & (1 << (bit)));
}



// Page table structures
align(1) union pmle {
	ulong[4096] padding;
	// Page map level 4 entry
	align(1) struct {
		ulong pmle;
		mixin(Bitfield!(pmle, "p", 1, "rw", 1, "us", 1, "pwt", 1, "pcd", 1, "a", 1,
		"ign", 1, "mbz", 2, "avl", 3, "pdpba", 41, "available", 10, "nx", 1));
	}
}

align(1) union pdpe {
	ulong[4096] padding;
	// Page directory pointer entry
	align(1) struct {
		ulong pdpe;
		mixin(Bitfield!(pdpe, "p", 1, "rw", 1, "us", 1, "pwt", 1, "pcd", 1, "a", 1,
		"ign", 1, "o", 1, "mbz", 1, "avl", 3, "pdba", 41, "available", 10, "nx", 1));
	}
}

align(1) union pde {
	ulong[4096] padding;
	// Page directory entry
	align(1) struct {
		ulong pde;
		mixin(Bitfield!(pde, "p", 1, "rw", 1, "us", 1, "pwt", 1, "pcd", 1, "a", 1,
		"ign1", 1, "o", 1, "ign2", 1, "avl", 3, "pdba", 41, "available", 10, "nx", 1));
	}
}

align(1) union pte {
	// Page table entry
	align(1) struct {
		ulong pte;
		mixin(Bitfield!(pte, "p", 1, "rw", 1, "us", 1, "pwt", 1, "pcd", 1, "a", 1,
		"d", 1, "pat", 1, "g", 1, "avl", 3, "pdba", 41, "available", 10, "nx", 1));
	}
}


// Function to establish 4k pages in memory
// Step 1: Get end of kernel / modules
// Step 2: Round to next 4096 mark
// Step 3: Claim the rest for ourselves

// Paramemters = addr: addr is an address passed to us by grub that contains the address to the multi-boot info :)
void fourK_pages(uint addr) {
	
	multiboot_info_t *mbi;
	
	mbi = cast(multiboot_info_t*)addr;
	uint pages_start_addr; // Address of where to start pages
	module_t* mod;
		
	if(CHECK_FLAG(mbi.flags, 6))
	{
		mod = cast(module_t*)mbi.mods_addr;
		mod = cast(module_t*)(cast(int)mod + (cast(int)mbi.mods_count - 1));
		uint endAddr = mod.mod_end;
		// print out the number of modules loaded by GRUB, and the physical memory address of the first module in memory.
		kprintfln("mods_count = %d, mods_addr = 0x%x", cast(int)mbi.mods_count, cast(int)mbi.mods_addr);
		kprintfln("mods_end = 0x%x", endAddr);
		
		// If endAddr is aligned already we'll just add 0, so no biggie
		pages_start_addr = endAddr + (endAddr % 4096);
		
		kprintfln("pages_start_addr = 0x%x", pages_start_addr);
	} else {
		kprintfln("The multi-boot struct was wrong!");
	}
	
}
