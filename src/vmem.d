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

// Bitmap of free pages
ubyte[] bitmap;
// CONST for page size
const ulong PAGE_SIZE = 4096;			// 4k pages for us right now
// Address of first available page
void* pages_start_addr;



void handle_faults(idt.interrupt_stack* ir_stack) 
{
	// First we need to determine why the page fault happened
	// This ulong will contain the address of the section of memory being faulted on
	void* addr;
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
	ubyte[4096] padding;
	// Page map level 4 entry
	align(1) struct {
		ulong pmle;
		mixin(Bitfield!(pmle, "p", 1, "rw", 1, "us", 1, "pwt", 1, "pcd", 1, "a", 1,
		"ign", 1, "mbz", 2, "avl", 3, "pdpba", 41, "available", 10, "nx", 1));
	}
}

align(1) union pdpe {
	ubyte[4096] padding;
	// Page directory pointer entry
	align(1) struct {
		ulong pdpe;
		mixin(Bitfield!(pdpe, "p", 1, "rw", 1, "us", 1, "pwt", 1, "pcd", 1, "a", 1,
		"ign", 1, "o", 1, "mbz", 1, "avl", 3, "pdba", 41, "available", 10, "nx", 1));
	}
}

align(1) union pde {
	ubyte[4096] padding;
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
void setup_vmem_bitmap(uint addr) {
	auto mbi = cast(multiboot_info_t*)addr;

	if(CHECK_FLAG(mbi.flags, 6))
	{
		auto mod = cast(module_t*)(cast(module_t*)mbi.mods_addr + mbi.mods_count - 1);
		ulong endAddr = mod.mod_end;

		// print out the number of modules loaded by GRUB, and the physical memory address of the first module in memory.
		kprintfln("mods_count = %d, mods_addr = 0x%x", cast(int)mbi.mods_count, cast(int)mbi.mods_addr);
		kprintfln("mods_end = 0x%x", endAddr);

		// If endAddr is aligned already we'll just add 0, so no biggie
		// Address of where to start pages
		pages_start_addr = cast(void*)(endAddr + (endAddr % PAGE_SIZE));			// Available start address for paging
		// Free space avail for pages
		ulong pages_free_size = (cast(ulong)mbi.mem_upper * 1024) - cast(ulong)pages_start_addr;		// Free space available to us

		kprintfln("Free space avail : %dKB", pages_free_size / 1024);
		
		
		kprintfln("pages_start_addr = 0x%x", pages_start_addr);
		kprintfln("Mem upper = %uKB", mbi.mem_upper);
		
		// Page allocator
		// Find the total number of pages in the system
		// Determine bitmap size
		// Total number of pages in teh system
		ulong num_pages =  (mbi.mem_upper * 1024) / PAGE_SIZE;
		kprintfln("Num of pages = %d", num_pages);
		
		// Size the bitmap needs to be
		ulong bitmap_size = (num_pages / 8);			// Bitmap size in bytes
		if(bitmap_size % PAGE_SIZE != 0) {			// If it is not 4k aligned
			bitmap_size += PAGE_SIZE - (bitmap_size % PAGE_SIZE);	// Pad the size off to keep things page aligned
		}
		
		kprintfln("Bitmap size in bytes = %d", bitmap_size);		

		// Set up bitmap
		// Return a ulong a ptr to the bitmap

		// The bitmap :)
		bitmap = (cast(ubyte*)pages_start_addr)[0 .. bitmap_size];

		// Now we need to properly set the used pages
		// First find the number of pages that are used
		// Number of used pages to init the mapping
		ulong num_used = (cast(ulong)pages_start_addr + bitmap_size) / PAGE_SIZE;	// Find number of used pages so far
		kprintfln("Number of used pages = %d", num_used);

		// Set the first part of the bitmap to all used
		bitmap[0 .. num_used / 8] = cast(ubyte)0xFF;
		
		// Where we change from used to unused, figure out the bit pattern to put in that slot
		bitmap[num_used / 8] = 0xFF >> (8 - (num_used % 8));
		
		// The reset of the bitmap is 0 to mean unused
		bitmap[num_used / 8 + 1 .. $] = 0;

	} else {
		kprintfln("The multi-boot struct was wrong!");
	}
}


// Request a page
// request_page(uint bitmap)
//	bitmap => pointer to the bitmap of allocated pages
// returns => uint pointer to a page

void* request_page() {
	// Iterate through the entire bitmap
	for(int i = 0; i < bitmap.length; i++) {
		// Iterate through the bitmap and check for a byte that is not full (free page)
		if(bitmap[i] < 0xFF) {
			// Find which page it is by shifting through the possible bits
			int z = 0;
			for(ubyte p = 1; p != 0; p <<= 1, z++) {
				// And anding it with the byte with free pages
				if((bitmap[i] & p) == 0) {
					// Now set that bit to taken
					bitmap[i] |= p;
					// Calculate the address of the page we need
					void* addr = cast(void*)(((i * 8) + z) * PAGE_SIZE);
					// Return the address of the free page
					return (addr);
				}
				
			}
		}
	}
	return null;
}

void free_page(void* address) {
	// Figure out which bit in the map we need to reset to 0
	ulong page = cast(ulong)(address) / PAGE_SIZE;
	ulong byte_num = page / 8;
	ulong bit_num = page % 8;
	
	ubyte mask = 1 << bit_num;
	
	bitmap[byte_num] &= (~mask);
	
	kprintfln("Returning bit %d; in byte %d of page %d\n", bit_num, byte_num, page);
}
