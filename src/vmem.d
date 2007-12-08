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
// Return a ulong (the ptr to our bitmap)
ulong fourK_pages(uint addr) {
	
	// CONST for page size
	const uint PAGE_SIZE = 4096;			// 4k pages for us right now
	
	
	multiboot_info_t *mbi;
	
	mbi = cast(multiboot_info_t*)addr;
	uint pages_start_addr; // Address of where to start pages
	module_t* mod;
		
	if(CHECK_FLAG(mbi.flags, 6))
	{
		mod = cast(module_t*)mbi.mods_addr;
		mod = cast(module_t*)(cast(int)mod + (cast(int)mbi.mods_count - 1));
		uint endAddr = mod.mod_end;
		uint pages_free_size;			// Free space avail for pages
		uint num_pages;					// Total number of pages in teh system
		uint bitmap_size;				// Size the bitmap needs to be	
		byte *bitmap;					// The bitmap :)	
		uint num_used;					// Number of used pages to init the mapping
				
		// print out the number of modules loaded by GRUB, and the physical memory address of the first module in memory.
		kprintfln("mods_count = %d, mods_addr = 0x%x", cast(int)mbi.mods_count, cast(int)mbi.mods_addr);
		kprintfln("mods_end = 0x%x", endAddr);
		
		// If endAddr is aligned already we'll just add 0, so no biggie
		pages_start_addr = endAddr + (endAddr % PAGE_SIZE);						// Available start address for paging
		pages_free_size = (cast(uint)mbi.mem_upper * 1024) - pages_start_addr;		// Free space available to us
		
		kprintfln("Free space avail : %dKB", pages_free_size / 1024);
		
		
		kprintfln("pages_start_addr = 0x%x", pages_start_addr);
		kprintfln("Mem upper = %uKB", mbi.mem_upper);
		
		// Page allocator
		// Find the total number of pages in the system
		// Determine bitmap size

		num_pages =  (mbi.mem_upper * 1024) / PAGE_SIZE;
		kprintfln("Num of pages = %d", num_pages);
		
		bitmap_size = (num_pages / 8);			// Bitmap size in bytes
		if(bitmap_size % PAGE_SIZE != 0) {			// If it is not 4k aligned
			bitmap_size += PAGE_SIZE - (bitmap_size % PAGE_SIZE);	// Pad the size off to keep things page aligned
			
		}
		
		kprintfln("Bitmap size in bytes = %d", bitmap_size);		
		
		// Set up bitmap
		// Return a ulong a ptr to the bitmap
		
		bitmap = cast(byte*)pages_start_addr;			// Pages start addr
		// Make the bitmap all 0s
		bitmap[0..bitmap_size] = 0;						// I can has bitmap?
		// Now we need to properly set the used pages
		// First find the number of pages that are used
		
		num_used = (pages_start_addr + bitmap_size) / PAGE_SIZE;	// Find number of used pages so far
		kprintfln("Number of used pages = %d", num_used);
		byte *temp = bitmap;
		int i;
		
		for(i = 0; i <= (num_used - 8); i+=8) {			// Set full bytes of pages used
			*temp = cast(byte)0xFF;
			temp += 1;
		}		
		if(num_used - i > 0) {
			*temp = 0xFF >> (8 - (num_used - i));			// Set the remaining bits
		}
		
		kprintfln("i was last seen indexing bit: %d", i);
		
		return cast(ulong)bitmap;
		
	} else {
		kprintfln("The multi-boot struct was wrong!");
	}
	
	return 0;
	
}
