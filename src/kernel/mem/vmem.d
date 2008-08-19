/* vmem.d - virtual memory stuffs
 *
 * So far just the page fault handler
 */


module kernel.mem.vmem;

import idt = kernel.arch.x86_64.idt;
import kernel.dev.vga;

import kernel.arch.locks;

import kernel.error;
import config;
import kernel.core.util;
import kernel.core.multiboot;

import kernel.mem.pmem;
import kernel.mem.vmem_structs; 


// Page Table Structures

align(1) struct pml4
{
	ulong pml4e;
	mixin(Bitfield!(pml4e, "present", 1, "rw", 1, "us", 1, "pwt", 1, "pcd", 1, "a", 1,
	"ign", 1, "mbz", 2, "avl", 3, "address", 41, "available", 10, "nx", 1));
}

// Page directory pointer entry
align(1) struct pml3
{
	ulong pml3e;
	mixin(Bitfield!(pml3e, "present", 1, "rw", 1, "us", 1, "pwt", 1, "pcd", 1, "a", 1,
	"ign", 1, "o", 1, "mbz", 1, "avl", 3, "address", 41, "available", 10, "nx", 1));
}


align(1) struct pml2
{
	ulong pml2e;
	mixin(Bitfield!(pml2e, "present", 1, "rw", 1, "us", 1, "pwt", 1, "pcd", 1, "a", 1,
	"ign1", 1, "o", 1, "ign2", 1, "avl", 3, "address", 41, "available", 10, "nx", 1));
}


align(1) struct pml1
{
	ulong pml1e;
	mixin(Bitfield!(pml1e, "present", 1, "rw", 1, "us", 1, "pwt", 1, "pcd", 1, "a", 1,
	"d", 1, "pat", 1, "g", 1, "avl", 3, "address", 41, "available", 10, "nx", 1));
}





// Entry point in to the page table
pml4[] pageLevel4;

// The kernel will always live in upper memory (across all page tables)
// to accomplish this, we'll put it in the SAME pageLevel3 for every
// table.  To do this we must keep track of the location of that level3
// in a variable called kernel_mapping
pml3[] kernel_mapping;


/* Handle faults -- the fault handler
 * This should handle everything when a page fault
 * occurs.
 */

struct vMem
{

	static:

	kmutex vMemMutex;

	// CONST for page size
	const ulong PAGE_SIZE = 4096;			// 4k pages for us right now
	const ulong VM_BASE_ADDR = 0xFFFFFF8000000000; // Base address for virtual addresses when accessing the physical memory
	                                        // that was mapped in to VM during our pages reinstall to prevent chicken/egg
	const ulong VM_BASE_INDEX = 0;	// This index is where on the pageLevel3[] the physical memory should start to be mapped in
	                            // Changing this value WILL IMPACT THE VALUE ABOVE IT!!!!!!!!!


	void fault_handler(idt.interrupt_stack* ir_stack) 
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

		//kprintfln!("\n Page fault. Code = {}, IP = 0x{x}, VA = 0x{x}, RBP = 0x{x}\n")(ir_stack.err_code, ir_stack.rip, addr, ir_stack.rbp);

		if((ir_stack.err_code & 1) == 0) 
		{
			//kprintfln!("Error due to page not present!")();

			if((ir_stack.err_code & 2) != 0)
			{
				//kprintfln!("Error due to write fault.")();
			}
			else
			{
				//kprintfln!("Error due to read fault.")();
			}

			if((ir_stack.err_code & 4) != 0)
			{
				//kprintfln!("Error occurred in usermode.")();
				// In this case we need to send a signal to the libOS handler
			}
			else
			{
				//kprintfln!("Error occurred in supervised mode.")();
				// In this case we're super concerned and need to handle the fault
			}

			if((ir_stack.err_code & 8) != 0)
			{
				//kprintfln!("Tried to read from a reserved field in PTE!")();
			}

			if((ir_stack.err_code & 16) != 0)
			{
				//kprintfln!("Instruction fetch error!")();
			}
		}
	}

	void install()
	{
		// This is not locked because the main cpu should run this before
		// any other cpus are initialized (it sort of has to be that way)

		// Allocate the physical page for the top-level page table.
	 	pageLevel4 = (cast(pml4*)pMem.request_page())[0 .. 512];
		
		auto kernel_size = (cast(ulong)pageLevel4.ptr / PAGE_SIZE);
		
		global_mem_regions.kernel.physical_start = cast(ubyte*)0x100000;
		global_mem_regions.kernel.virtual_start = cast(ubyte*)0xffffffff80000000;
		global_mem_regions.kernel.length = kernel_size;
		// kernel_vm_end will be used for house keeping later
		//kernel_vm_end = (kernel_size * PAGE_SIZE);

		//kernel_vm_end += PAGE_SIZE + kernel_vm_start;
		
		// zero it out.
		pageLevel4[] = pml4.init;
		
		// Put the kernel in to the top X pages of vmemory

		// So where does our kernel actually live in physical memory?
		// Well if our physical page allocator works correctly then
		// we know that we have the first page after the kernel for
		// our PML4.  This means we can just jack that address,
		// and used it to determine our kernel size (we hope)!

		// Remapping time!  This will remap the kernel in to high memory (again)
		// Though we did this in the asm, we are doing it again in here so that it
		// is easier to work with (has structs, etc that we can play with)

		// 3rd level page table
		pml3[] pageLevel3 = (cast(pml3*)pMem.request_page())[0 .. 512];
		
		
		pageLevel3[] = pml3.init;
		// Make sure we know where the kernel is living FO REALS!
		kernel_mapping = pageLevel3[];

		// Set the 511th entry of level 4 to a level 3 entry
		pageLevel4[511].pml4e = cast(ulong)pageLevel3.ptr;
		// Set correct flags, present, rw, usable
		pageLevel4[511].pml4e |= 0x7;
	   
		// Create a level 2 entry
		pml2[] pageLevel2 = (cast(pml2*)pMem.request_page())[0 .. 512];
		
		
		pageLevel2[] = pml2.init;
		
		// Set the 511th entry of level 3 to a level 2 entry
		pageLevel3[510].pml3e = cast(ulong)pageLevel2.ptr;
		// Set correct flags, present, rw, usable
		pageLevel3[510].pml3e |= 0x7;

		// forward reference a page level 1 array
		pml1[] pageLevel1;

		auto addr = 0x00; 		// Current addr
		
		for(int i = 0, j = 0; i < kernel_size; i += 512, j++) {
			// Make some page table entries
			pageLevel1 = (cast(pml1*)pMem.request_page())[0 .. 512];

			// Set pml2e to the pageLevel 1 entry
			pageLevel2[j].pml2e = cast(ulong)pageLevel1.ptr;
			pageLevel2[j].pml2e |= 0x7;
			
			// Now map all the physical addresses :)  YAY!
			for(int z = 0; z < 512; z++) {
				pageLevel1[z].pml1e = addr;
				pageLevel1[z].pml1e |= 0x87;
				addr += 4096;
			}
		}
		
		// Lets map in all of our phyiscal memory here, just so we can write to it
		// without a chicken and the egg problem...
		map_ram(pageLevel3);

		// establish the kernel mapped area (after RAM mapping)
		// this is for devices and bios regions
		global_mem_regions.kernel_mapped.virtual_start = global_mem_regions.system_memory.virtual_start + global_mem_regions.system_memory.length;
		global_mem_regions.kernel_mapped.length = 0;

		// the physical start of the kernel mapping is not known
		global_mem_regions.kernel_mapped.physical_start = global_mem_regions.kernel_mapped.virtual_start;
		
		//kprintfln!("virtual mapping starts: {x}")(global_mem_regions.kernel_mapped.virtual_start);


		//kprintfln!("kernel_size in pages = {}")(kernel_size);
		//kprintfln!("kernel_size in bytes = {}")(kernel_size * PAGE_SIZE);
		//kprintfln!("PageLevel 4 addr = {}")(pageLevel4.ptr);
		//kprintfln!("Pagelevel 3 addr = {}, {x}")(pageLevel3.ptr, pageLevel4[511].pml4e);
		//kprintfln!("Pagelevel 2 addr = {}, {x}")(pageLevel2.ptr, pageLevel3[510].pml3e);
		//kprintfln!("Pagelevel 1 addr = {x}")(pageLevel2[0].pml2e);

		pml1[] tmp = (cast(pml1*)(pageLevel2[1].pml2e - 0x7))[0 .. 512];

		//kprintfln!("Page address: {x}")(tmp[0].pml1e);

		asm {
			"mov %0, %%rax" :: "o" pageLevel4.ptr;
			"mov %%rax, %%cr3";
		}

		// And now, for benefit of great gods in sky, we add VM_BASE_ADDR to
		// pageLevel4.ptr so that the CPU does't fail when trying to read a physical
		// address!
		pageLevel4 = (cast(pml4*)(cast(void*)pageLevel4.ptr + VM_BASE_ADDR) )[0 .. 512];
		
		pageLevel3 = get_pml3(511);

		//kprintfln!("Done Mapping ... {}")(pageLevel3[0].present);
	}

	private void map_ram(ref pml3[] pageLevel3)
	{
		// forward reference a page level 1 and 2 array
		pml2[] pageLevel2;
		pml1[] pageLevel1;

		ulong addr = 0x00;

		// Do da mappin'
		ulong i = 0;
		ulong pageLimit = ((pMem.mem_size-1) / PAGE_SIZE);

		for(int k = VM_BASE_INDEX; i <= pageLimit; k++) 
		{
			pageLevel2 = (cast(pml2*)pMem.request_page())[0 .. 512];
	
			pageLevel2[] = pml2.init;
			pageLevel3[k].pml3e = cast(ulong)pageLevel2.ptr;
			pageLevel3[k].pml3e |= 0x7;

			for(int j = 0; i <= pageLimit && j < 512; i += 512, j++)
			{
				// Make some page table entries
				pageLevel1 = (cast(pml1*)pMem.request_page())[0 .. 512];
	
				// Set pml2e to the pageLevel 1 entry
				pageLevel2[j].pml2e = cast(ulong)pageLevel1.ptr;
				pageLevel2[j].pml2e |= 0x7;
				
				// Now map all the physical addresses :)  YAY!
				for(int z = 0; z < 512; z++) {
					pageLevel1[z].pml1e = addr;
					pageLevel1[z].pml1e |= 0x87;
					addr += 4096;
				}
			}
		}

		// establish the RAM region
		global_mem_regions.system_memory.virtual_start = cast(ubyte*)VM_BASE_ADDR;
		global_mem_regions.system_memory.physical_start = cast(ubyte*)0;
		global_mem_regions.system_memory.length = i * 4096;
	}

	// This function will take a physical range (a BIOS region, perhaps) and
	// map it after the end of the physical address range
	ErrorVal map_range(ubyte* physicalRangeStart, ulong physicalRangeLength, out ubyte* virtualRangeStart)
	{
		// the physical range needs to be aligned by the page
		if (cast(ulong)physicalRangeStart & (PAGE_SIZE-1))
		{
			// Not aligned
			return ErrorVal.BadInputs;
		}

		vMemMutex.lock();

		ubyte* physicalRangeEnd = physicalRangeStart + physicalRangeLength;

		// the physical end must be aligned by 4K (the length must be a factor of 4K)
		if (physicalRangeLength & (PAGE_SIZE-1))
		{
			// Not aligned
			// align it
			physicalRangeLength += PAGE_SIZE;
			physicalRangeLength -= (physicalRangeLength & (PAGE_SIZE-1));
		}

		// the physical range cannot be invalid due to overflow
		if (physicalRangeEnd < physicalRangeStart)
		{
			// bah! bad input, range invalid
			return ErrorVal.BadInputs;
		}

		// now that we have a valid range, we can map to the kernel

		// set the virtual range, it will be returned from the function
		virtualRangeStart = global_mem_regions.kernel_mapped.virtual_start + global_mem_regions.kernel_mapped.length;

		//kprintfln!("start: {} {} {}")(virtualRangeStart, global_mem_regions.kernel_mapped.virtual_start, pMem.mem_size);
		// get the initial page tables to alter

		// increment the kernel mapping region
		global_mem_regions.kernel_mapped.length += physicalRangeLength;

		pml3[] pl3;
		pml2[] pl2;
		pml1[] pl1;

		long pml_index4;
		long pml_index3;
		long pml_index2;
		long pml_index1;

		// get the initial page table entry to set, allocating page tables as necessary
		allocate_page_entries(virtualRangeStart, pl3, pl2, pl1, pml_index4, pml_index3, pml_index2, pml_index1);

		retrieve_page_entries(virtualRangeStart, pl3, pl2, pl1, pml_index4, pml_index3, pml_index2, pml_index1);

		pl2 = get_pml2(pl3, pml_index3);
		pl1 = get_pml1(pl2, pml_index2);

		// map each page
		for ( ; ; )
		{
			// set page level 1, unless all have been set
			// when page level 1 is full, move on to page level 2
			// shouldn't move along page level 4, would mean overwriting
			// kernel code mapping...

			// should ensure that only new pages get added
			// if any are overwritten, this would mean death
			
			// Step One:
			//  --  set the current page table entry

			if (pl1[pml_index1].present)
			{
				// this page table entry has already been
				// set, this is a huge deal, something is
				// in the kernel mapping space
				vMemMutex.unlock();				
				return ErrorVal.Fail;
			}

			pl1[pml_index1].pml1e = cast(ulong)physicalRangeStart;
			pl1[pml_index1].pml1e |= 0x87;
			
			physicalRangeStart += PAGE_SIZE;
			if (physicalRangeStart >= physicalRangeEnd)
			{
				break;
			}

			pml_index1++;
			if (pml_index1 == 512)
			{
				// we must go onto the next page level 2
				pml_index1 = 0;
				pml_index2++;

				if (pml_index2 == 512)
				{
					pml_index2 = 0;
					pml_index3++;

					if (pml_index3 == 512)
					{
						// crap! we are screwed!

						// we cannot progress over the
						// last page table, we risk overwriting
						// kernel code mapping

						// although, we could simply fail on seeing
						// an already mapped page table entry, I'd
						// rather not risk it.
						vMemMutex.unlock();
						return ErrorVal.Fail;
					}

					pl2 = get_pml2(pl3, pml_index3);
					if (pl2 is null)
					{
						pl2 = allocate_pml2(pl3, pml_index3);
					}
				}
				
				pl1 = get_pml1(pl2, pml_index2);
				if (pl1 is null)
				{
					pl1 = allocate_pml1(pl2, pml_index2);
				}
			}
		}
		
		//kprintfln!("virtual Start: {x} for length: {}")(virtualRangeStart, physicalRangeLength);

		vMemMutex.unlock();
		return ErrorVal.Success;
	}

	// Function to get a physical page of memory and map it in to virtual memory
	// Returns: 1 on success, -1 on failure
	ErrorVal get_page(bool usermode)(void* vm_address) {

		vMemMutex.lock();

		ulong vm_addr_long = cast(ulong)vm_address;
		//kprintfln!("The kernel end page addr in physical memory = {x}")(vm_addr_long);
		
		// Request a page of physical memory
		auto phys = pMem.request_page();
		
		static if(usermode)
			kprintfln!("physical address: {}")(phys);

		// Make sure we know where the end of the kernel now is

		ulong vm_addr = vm_addr_long;

		// Arrays for later traversal
		pml3[] pl3;
		pml2[] pl2;
		pml1[] pl1;

		// Shift our VM address right by 12 bits
		vm_addr_long >>= 12;

		long pml_index1 = vm_addr_long & 0x1FF;

		vm_addr_long >>= 9;
		long pml_index2 = vm_addr_long & 0x1FF;
		
		vm_addr_long >>= 9;
		long pml_index3 = vm_addr_long & 0x1FF;
		
		vm_addr_long >>= 9;
		long pml_index4 = vm_addr_long & 0x1FF;

		// Get the index in to the page table
		//kprintfln!("level 4 Index = {}")(pml_index);
		// Check to see if the level 4 [entry] is there (it damn well better be if it does't want to be hit... again)
		
		pl3 = allocate_pml3(pml_index4, usermode);

		pl2 = allocate_pml2(pl3, pml_index3, usermode);
		
		pl1 = allocate_pml1(pl2, pml_index2, usermode);

		// We need to ensure that we aren't writing to a page that is already mapped.s
		if(!pl1[pml_index1].present)
		{
			with(pl1[pml_index1])
			{
				// set the whole address, which will also conveniently set the
				// first 12 flag bits to zero.
				pml1e = cast(ulong)phys;

				// set initial bits
				present = true;
				rw = true;
				us = usermode;
			}
		} else {
			vMemMutex.unlock();
			return ErrorVal.PageMapError;
		}
		vMemMutex.unlock();
		
		// The page table puts the lotion on its skin or it gets the hose again...
		return ErrorVal.Success;
	}

	alias get_page!(false) get_kernel_page;
	alias get_page!(true) get_user_page;

	// free_page(void* pageAddr) -- this function will free a virtual page
	// by setting its available bit
	ErrorVal free_page(void* pageAddr) {

		vMemMutex.lock();

		// Step 1: Traverse page table
		// Step 2: Set call free_phys_mem with physical address
		// Step 3: Reset present bit on free'd page
		// Step 4: profit

		// Shift the page address right 12 bits (skip the crap)

		// And it to get the index in to the level 4
		
		pml3[] pl3;
		pml2[] pl2;
		pml1[] pl1;

		long pml_index4;
		long pml_index3;
		long pml_index2;
		long pml_index1;

		retrieve_page_entries(pageAddr, pl3, pl2, pl1, pml_index4, pml_index3, pml_index2, pml_index1);
		
		if (pl1 is null)
		{
			// this virtual address is invalid
			vMemMutex.unlock();
			return ErrorVal.BadInputs;
		}

		// Step 2: Set call free_phys_mem with physical address
		pMem.free_page(cast(void*)(pl1[pml_index1].pml1e & ~0x87));
		
		// Step 3: Reset present bit on free'd page
		// Now lets set the page as absent in virtual memory :)
		pl1[pml_index1].pml1e &= ~0x1;



		// Step 4: profit?!?!




		vMemMutex.unlock();


		return ErrorVal.Success;
	}

	private void retrieve_page_entries(void* virtual_address, out pml3[] pl3, out pml2[] pl2, out pml1[] pl1, out long pml_index4, out long pml_index3, out long pml_index2, out long pml_index1)
	{
		ulong v_address = (cast(ulong)virtual_address) >> 12;

		pml_index1 = v_address & 0x1FF;
		
		v_address >>= 9;
		pml_index2 = v_address & 0x1FF;
		
		v_address >>= 9;
		pml_index3 = v_address & 0x1FF;

		v_address >>= 9;
		pml_index4 = v_address & 0x1FF;
		
		//kprintfln!("{} {} {} {}")(pml_index4, pml_index3, pml_index2, pml_index1);

		// Step 1: Traversing the page table

		pl3 = get_pml3(pml_index4);
		if (pl3 is null)
		{
			// this virtual address has not been mapped
			pl2 = null;
			pl1 = null;
			return;
		}

		pl2 = get_pml2(pl3, pml_index3);
		if (pl2 is null)
		{
			// this virtual address has not been mapped
			pl1 = null;
			return;
		}

		pl1 = get_pml1(pl2, pml_index2);
	}

	private ErrorVal allocate_page_entries(void* virtualAddress, out pml3[] pl3, out pml2[] pl2, out pml1[] pl1, out long pml_index4, out long pml_index3, out long pml_index2, out long pml_index1)
	{
		retrieve_page_entries(virtualAddress, pl3, pl2, pl1, pml_index4, pml_index3, pml_index2, pml_index1);

		if (pl3 is null)
		{
			// need to allocate page level 3 before we continue
			pl3 = allocate_pml3(pml_index4);
		}
		
		if (pl2 is null)
		{
			// need to allocate page level 2 before we continue
			pl2 = allocate_pml2(pl3, pml_index3);
		}
		
		if (pl1 is null)
		{
			// need to allocate page level 1 before we continue
			pl1 = allocate_pml1(pl2, pml_index2);
		}

		return ErrorVal.Success;
	}




	// These spawn functions basically create a new pmlX[], and save us from having
	// to retype the two lines of code every time.  Yay code reuse!?
	private pml3[] spawn_pml3() {
		pml3[] pl3 = (cast(pml3*)(pMem.request_page() + VM_BASE_ADDR))[0 .. 512];
		pl3[] = pml3.init;
		
		return pl3[];
	}


	private pml2[] spawn_pml2() {
		pml2[] pl2 = (cast(pml2*)(pMem.request_page() + VM_BASE_ADDR))[0 .. 512];
		pl2[] = pml2.init;
		
		return pl2[];
	}

	private pml1[] spawn_pml1() {
		pml1[] pl1 = (cast(pml1*)(pMem.request_page() + VM_BASE_ADDR))[0 .. 512];
		pl1[] = pml1.init;

		return pl1[];
	}




	private pml3[] get_pml3(ulong pml_index4)
	{
		ulong addr = pageLevel4[pml_index4].address << 12;
		if (!pageLevel4[pml_index4].present)
		{
			return null;
		}
		return (cast(pml3*)((addr + VM_BASE_ADDR)))[0 .. 512];
	}

	private pml2[] get_pml2(ref pml3[] pl3, ulong pml_index3)
	{
		ulong addr = pl3[pml_index3].address << 12;
		if (!pl3[pml_index3].present)
		{
			return null;
		}
		return (cast(pml2*)((addr + VM_BASE_ADDR)))[0 .. 512];
	}

	private pml1[] get_pml1(ref pml2[] pl2, ulong pml_index2)
	{
		ulong addr = pl2[pml_index2].address << 12;
		if (!pl2[pml_index2].present)
		{
			return null;
		}
		return (cast(pml1*)((addr + VM_BASE_ADDR)))[0 .. 512];
	}




	private pml3[] allocate_pml3(ulong pml_index4, bool usermode = false)
	{
		if (!pageLevel4[pml_index4].present)
		{
			pml3[] pl3 = spawn_pml3();
			
			with(pageLevel4[pml_index4])
			{
				// set the whole address, which will also conveniently set the
				// first 12 flag bits to zero.
				pml4e = (cast(ulong)pl3.ptr) - VM_BASE_ADDR;

				// set initial bits
				present = true;
				rw = true;
				us = usermode;
			}
			
			return pl3;
		}
		ulong addr = pageLevel4[pml_index4].pml4e;
		return (cast(pml3*)((addr + VM_BASE_ADDR) & ~0x7))[0 .. 512];
	}

	private pml2[] allocate_pml2(pml3[] pl3, ulong pml_index3, bool usermode = false)
	{
		if (!pl3[pml_index3].present)
		{
			pml2[] pl2 = spawn_pml2();
			
			with(pl3[pml_index3])
			{
				// set the whole address, which will also conveniently set the
				// first 12 flag bits to zero.
				pml3e = (cast(ulong)pl2.ptr) - VM_BASE_ADDR;

				// set initial bits
				present = true;
				rw = true;
				us = usermode;
			}
			
			return pl2;
		}
		ulong addr = pl3[pml_index3].pml3e;
		return (cast(pml2*)((addr + VM_BASE_ADDR) & ~0x7))[0 .. 512];
	}

	private pml1[] allocate_pml1(pml2[] pl2, ulong pml_index2, bool usermode = false)
	{
		if (!pl2[pml_index2].present)
		{
			pml1[] pl1 = spawn_pml1();
			
			with(pl2[pml_index2])
			{
				// set the whole address, which will also conveniently set the
				// first 12 flag bits to zero.
				pml2e = (cast(ulong)pl1.ptr) - VM_BASE_ADDR;

				// set initial bits
				present = true;
				rw = true;
				us = usermode;
			}
			
			return pl1;
		}
		ulong addr = pl2[pml_index2].pml2e;
		return (cast(pml1*)((addr + VM_BASE_ADDR) & ~0x7))[0 .. 512];
	}
}
