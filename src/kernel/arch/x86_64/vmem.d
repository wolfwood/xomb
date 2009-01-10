/* vmem.d - virtual memory stuffs */


module kernel.arch.x86_64.vmem;

import kernel.dev.vga;

import kernel.arch.locks;
import kernel.arch.x86_64.idt;

import kernel.core.error;
import config;
import kernel.core.util;
import kernel.core.multiboot;

import kernel.mem.pmem;
import kernel.core.regions;

// Memory Layout
//
// x86, 4 level page tables
//
// PL4[511] - Shared Kernel Memory
//			PL3[511] - Kernel Mapping, kHeap
//			PL3[510] - RAM Mapping, Device Mapping, Region Mapping
//			  ...
//			PL3[0]
// PL4[510] - Local To CPU Memory (one per cpu)
//			PL3[511]
//				PL2[511]
//					PL1[511] - KERNEL_STACK
//					  ...
//					PL1[510]
//					PL1[509] - CPU_INFO
// PL4[509] - Local to Environment Memory (one per environment, per cpu)
//			PL3[511]
//				PL2[511]
//					PL1[511] - ENVIRONMENT_STACK
//					  ...
//					PL1[510]
//					PL1[509] - REGISTER_STACK
//					  ...
//					PL1[0] - DEVICE HEAP
// PL4[0] - Environment space
//			PL3[0] - Environment shared among all cpus + heap

// Kernel Page Table: vMem.pageLevel4
// CPU Page Table: Cpu.pageLevel4[]
// Enviroment Page Table: Environment.pageTables[] of type pml1, represents pl4[509].pl3[511].pl2[511] and
//								Environment.content of type pml3, represents pl4[0]

struct vMem
{

static:

// Page Table Structures (for userspace environments)

template FormVirtualAddress(ulong pl4, ulong pl3, ulong pl2, ulong pl1)
{
	static if (pl4 & 0x100) // if bit 8 is set, high canonical
	{
		const ulong FormVirtualAddress = 0xFFFF000000000000 | (pl1 << 12) | (pl2 << (12 + 9)) | (pl3 << (12 + 9 + 9)) | (pl4 << (12 + 9 + 9 + 9));
	}
	else
	{
		const ulong FormVirtualAddress = (pl1 << 12) | (pl2 << (12 + 9)) | (pl3 << (12 + 9 + 9)) | (pl4 << (12 + 9 + 9 + 9));
	}
}

// Page Size constant
const ulong PAGE_SIZE = 4096;			// 4k pages for us right now

// size of the kernel stack
const ulong KERNEL_STACK_PAGES = 1;

// size of the user stack
const ulong ENVIRONMENT_STACK_PAGES = 2;

// size of the register stack (context switch storage)
const ulong REGISTER_STACK_PAGES = 1;

// size of the cpu info page
const ulong CPU_INFO_PAGES = 1;

// register stack
const ulong REGISTER_STACK = (FormVirtualAddress!(509,511,511,512 - ENVIRONMENT_STACK_PAGES - REGISTER_STACK_PAGES)) + (REGISTER_STACK_PAGES * PAGE_SIZE);

// address of bottom of register stack
const ulong REGISTER_STACK_POS = REGISTER_STACK - (PAGE_SIZE * REGISTER_STACK_PAGES);

// user stack
const ulong ENVIRONMENT_STACK = (FormVirtualAddress!(509,511,511,512 - ENVIRONMENT_STACK_PAGES)) + (ENVIRONMENT_STACK_PAGES * PAGE_SIZE);

// kernel stack
const ulong KERNEL_STACK = (FormVirtualAddress!(510,511,511,512 - KERNEL_STACK_PAGES)) + (KERNEL_STACK_PAGES * PAGE_SIZE);

// cpu info
const ulong CPU_INFO_ADDR = (FormVirtualAddress!(510,511,511,512 - KERNEL_STACK_PAGES - CPU_INFO_PAGES));

// cpu page table
const ulong CPU_PAGETABLE_ADDR = (FormVirtualAddress!(510,511,511,512-KERNEL_STACK_PAGES - CPU_INFO_PAGES - 1));

// environment device page start
const ulong ENVIRONMENT_DEVICE_HEAP_START = (FormVirtualAddress!(509,511,511,0));

// RAM mapping
const ulong VM_BASE_INDEX = 0;	// This index is where on the pageLevel3[] the physical memory should start to be mapped in
	                            // Changing this value WILL IMPACT THE VALUE BELOW IT!!!!!!!!!

const ulong VM_BASE_ADDR = FormVirtualAddress!(511,VM_BASE_INDEX,0,0); // Base address for virtual addresses when accessing the physical memory
	                                        // that was mapped in to VM during our pages reinstall to prevent chicken/egg



align(1) struct PageTable
{
	pml4* entries;

	void* virtStart;
	void* virtEnd;

    long codePages;
	long heapPages;
	long devicePages;

	// initialize a user page table
	void init(uint numCpus)
	{
		// get a free page
		void* nextAddr;
		nextAddr = pMem.requestPage();
		//kprintfln!("pl4: {x}")(nextAddr);
		nextAddr += VM_BASE_ADDR;

		entries = cast(pml4*)nextAddr;

		// set to defaults
		entries[0..511] = pml4.init;

		// map in the kernel
		entries[511].pml4e = (cast(pml4*)CPU_PAGETABLE_ADDR)[511].pml4e;
	}

	void uninit()
	{
		// free the pages used
		pml3* pl3;
		pml2* pl2;
		pml1* pl1;

		// free entire pagetable from all levels

		// stop short of kernel mapping (pl4[511])
		for (int i=0; i<511; i++)
		{ // look at level 3s
			pl3 = getPml3(entries, i);

			if (pl3 !is null)
			{
				for (int j=0; j<512; j++)
				{ // look at level 2s
					pl2 = getPml2(pl3, j);

					if (pl2 !is null)
					{
						for (int k=0; k<512; k++)
						{ // look at level 1s
							pl1 = getPml1(pl2, k);

							if (pl1 !is null) {
								pMem.freePage((cast(void*)pl1) - VM_BASE_ADDR);
							}
						}

						pMem.freePage((cast(void*)pl2) - VM_BASE_ADDR);
					}
				}

				pMem.freePage((cast(void*)pl3) - VM_BASE_ADDR);
			}
		}

//		kprintfln!("pl4: {x} {x}")(entries, VM_BASE_ADDR);

		// free level 4
		pMem.freePage((cast(void*)entries) - VM_BASE_ADDR);
	}

	ErrorVal mapStack(out void* stack)
	{
		pml1* pl1;
		pml2* pl2;
		pml3* pl3;

		long pml_index4;
		long pml_index3;
		long pml_index2;
		long pml_index1;

		void* virtualAddress = cast(void*)(ENVIRONMENT_STACK - (ENVIRONMENT_STACK_PAGES * PAGE_SIZE));

		while (virtualAddress != cast(void*)ENVIRONMENT_STACK)
		{
			stack = pMem.requestPage();

			allocateUserPageEntries(virtualAddress, pl3, pl2, pl1, pml_index4, pml_index3, pml_index2, pml_index1, entries);

			//kprintfln!("estack: {x} {} {} {} {}")(virtualAddress, pml_index4, pml_index3, pml_index2, pml_index1);

			// we set the entry to point to the newly allocated page
			pl1[pml_index1].pml1e = (cast(ulong)stack) | 0x87; // present!
			pl1[pml_index1].us = 1; // user mode access

			virtualAddress += PAGE_SIZE;

		}

		stack = cast(void*)ENVIRONMENT_STACK;

		return ErrorVal.Success;
	}

	ErrorVal mapRegisterStack(out void* registerStack)
	{
		pml1* pl1;
		pml2* pl2;
		pml3* pl3;

		long pml_index4;
		long pml_index3;
		long pml_index2;
		long pml_index1;

		void* virtualAddress = cast(void*)(REGISTER_STACK - (REGISTER_STACK_PAGES * PAGE_SIZE));

		while (virtualAddress != cast(void*)REGISTER_STACK)
		{
			registerStack = pMem.requestPage();

			allocateKernelPageEntries(virtualAddress, pl3, pl2, pl1, pml_index4, pml_index3, pml_index2, pml_index1, entries);

			//kprintfln!("rstack: {x} {} {} {} {}")(virtualAddress, pml_index4, pml_index3, pml_index2, pml_index1);

			// we set the entry to point to the newly allocated page
			pl1[pml_index1].pml1e = (cast(ulong)registerStack) | 0x87; // present!

			virtualAddress += PAGE_SIZE;

		}

		registerStack = cast(void*)REGISTER_STACK;

		return ErrorVal.Success;
	}

	// This function will take a physical range (a BIOS region, perhaps) and
	// map it after the end of the physical address range
	ErrorVal map(ubyte* physicalRangeStart, ulong physicalRangeLength, void* virtualStart)
	{
		// the physical range needs to be aligned by the page
		if (cast(ulong)physicalRangeStart & (PAGE_SIZE-1))
		{
			// Not aligned
			return ErrorVal.BadInputs;
		}

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

		codePages = physicalRangeLength / PAGE_SIZE;
		heapPages = 0;

		// now that we have a valid range, we can map to the kernel

		// set the virtual address
		void* virtualRangeStart = virtualStart; //physicalRangeStart;
		virtStart = virtualStart;
		virtEnd = virtStart + physicalRangeLength;

		//kdebugfln!(DEBUG_PAGING | true, "start: {} {} {}")(virtualRangeStart, global_mem_regions.kernel_mapped.virtual_start, pMem.mem_size);
		// get the initial page tables to alter

		// increment the kernel mapping region
		//global_mem_regions.kernel_mapped.length += physicalRangeLength;

		pml3* pl3;
		pml2* pl2;
		pml1* pl1;

		long pml_index4;
		long pml_index3;
		long pml_index2;
		long pml_index1;

		// get the initial page table entry to set, allocating page tables as necessary
		allocateUserPageEntries(virtualRangeStart, pl3, pl2, pl1, pml_index4, pml_index3, pml_index2, pml_index1, entries);


		//kprintfln!("a{} {} {} {}")(pml_index4, pml_index3, pml_index2, pml_index1);



		//retrievePageEntries(virtualRangeStart, pl3, pl2, pl1, pml_index4, pml_index3, pml_index2, pml_index1);


		//kprintfln!("1{} {} {} {}")(pml_index4, pml_index3, pml_index2, pml_index1);

	//pl3 = getPml3(entries, pml_index4);

		//kprintfln!("2{} {} {} {}")(pml_index4, pml_index3, pml_index2, pml_index1);

	//pl2 = getPml2(pl3, pml_index3);

		//kprintfln!("3{} {} {} {}")(pml_index4, pml_index3, pml_index2, pml_index1);

	//pl1 = getPml1(pl2, pml_index2);

		//kprintfln!("b{} {} {} {}")(entries, pl3, pl2, pl1);


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

			//kprintfln!("{} {} {} {}")(pml_index4, pml_index3, pml_index2, pml_index1);

			if (pl1[pml_index1].present)
			{
				// this page table entry has already been set...
				// no good

				return ErrorVal.Fail;
			}

			pl1[pml_index1].pml1e = cast(ulong)physicalRangeStart;
			pl1[pml_index1].pml1e |= 0x87;
			pl1[pml_index1].us = 1; // flag as userspace

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

						pml_index3 = 0;
						pml_index4++;

						if (pml_index4 == 512)
						{
							// cannot get this far without failiing.
							// fail nonetheless
							return ErrorVal.Fail;
						}

						pl3 = getPml3(entries, pml_index4);
						if (pl3 is null)
						{
							pl3 = allocatePml3(entries, pml_index4, true);
						}
					}

					pl2 = getPml2(pl3, pml_index3);
					if (pl2 is null)
					{
						pl2 = allocatePml2(pl3, pml_index3, true);
					}
				}

				pl1 = getPml1(pl2, pml_index2);
				if (pl1 is null)
				{
					pl1 = allocatePml1(pl2, pml_index2, true);
				}
			}
		}

		kdebugfln!(DEBUG_PAGING, "virtual Start: {x} for length: {}")(virtualRangeStart, physicalRangeLength);

		return ErrorVal.Success;
	}

	// TODO: lock these pages down!!!
	void* allocPages(int amt)
	{
		//kprintfln!("allocation")();
		void* ret = virtEnd;

		for (; amt > 0; amt--)
		{
			//kprintfln!("inner loop")();
			void* physPage = pMem.requestPage();

			pml3* pl3;
			pml2* pl2;
			pml1* pl1;

			long pml_index4;
			long pml_index3;
			long pml_index2;
			long pml_index1;

			allocateUserPageEntries(virtEnd, pl3, pl2, pl1, pml_index4, pml_index3, pml_index2, pml_index1, entries);

			if (pl1[pml_index1].present)
			{
				// no good
				//kprintfln!("allocPages() : bad!")();
				return null;
			}

			//kprintfln!("allocating : {x} to {x}")(virtEnd, physPage);

			//kprintfln!("{x} : {} {} {} {}")(virtEnd, pml_index4, pml_index3, pml_index2, pml_index1);

			//kprintfln!("prev entry: {x}")(pl1[pml_index1-1].address << 12);

			//kprintfln!("entries: {x}")(entries);

			pl1[pml_index1].pml1e = cast(ulong)physPage;
			pl1[pml_index1].pml1e |= 0x87;
			pl1[pml_index1].us = 1; // userspace flag

      kprintfln!("addr = {}")(physPage);

			virtEnd += vMem.PAGE_SIZE;

			heapPages++;
		}

		return ret;
	}

	void freePages(int amt)
	{
		for (; amt > 0; amt--)
		{
			if (heapPages == 0) { return; }

			pml3* pl3;
			pml2* pl2;
			pml1* pl1;

			long pml_index4;
			long pml_index3;
			long pml_index2;
			long pml_index1;

			virtEnd -= vMem.PAGE_SIZE;

			retrievePageEntries(virtEnd, pl3, pl2, pl1, pml_index4, pml_index3, pml_index2, pml_index1, entries);

      kprintfln!("pm1: {}")(pml_index1);

			ulong physAddr = pl1[pml_index1].address;
			physAddr <<= 12;

      kprintfln!("physAddr = {}")(physAddr);

			pl1[pml_index1].pml1e = 0;

			pMem.freePage(cast(void*)physAddr);

			heapPages--;
		}
	}

	// TODO: lock these pages down!!!
	void* allocDevicePage(out void* virtAddr, bool allowWrite, void* physPage = null)
	{
		void* ret = cast(void*)ENVIRONMENT_DEVICE_HEAP_START;
		ret += vMem.PAGE_SIZE * devicePages;

		// true: will set a bit in the page table entry
		// that says this page's physical page should
		// not be freed
		bool noPhysAlloc = true;

		if (physPage is null)
		{
			noPhysAlloc = false;
			physPage = pMem.requestPage();
		}

		virtAddr = cast(void*)(cast(ulong)physPage + vMem.VM_BASE_ADDR);

		pml3* pl3;
		pml2* pl2;
		pml1* pl1;

		long pml_index4;
		long pml_index3;
		long pml_index2;
		long pml_index1;

		allocateUserPageEntries(ret, pl3, pl2, pl1, pml_index4, pml_index3, pml_index2, pml_index1, entries);

		if (pl1[pml_index1].present)
		{
			// no good
			//kprintfln!("allocPages() : bad!")();
			return null;
		}

		//kprintfln!("allocating : {x} to {x}")(virtEnd, physPage);

		//kprintfln!("{x} : {} {} {} {}")(virtEnd, pml_index4, pml_index3, pml_index2, pml_index1);

		//kprintfln!("prev entry: {x}")(pl1[pml_index1-1].address << 12);

		//kprintfln!("entries: {x}")(entries);

		pl1[pml_index1].pml1e = cast(ulong)physPage;
		pl1[pml_index1].pml1e |= 0x87;
		pl1[pml_index1].rw = allowWrite;
		pl1[pml_index1].noPhysAlloc = noPhysAlloc;
		pl1[pml_index1].us = 1; // userspace flag

		devicePages++;

		return ret;
	}

	void freeDevicePages()
	{
		void* devicePageStart = cast(void*)ENVIRONMENT_DEVICE_HEAP_START;

		for ( ; devicePages>0 ; devicePages-- )
		{
			pml3* pl3;
			pml2* pl2;
			pml1* pl1;

			long pml_index4;
			long pml_index3;
			long pml_index2;
			long pml_index1;

			retrievePageEntries(devicePageStart, pl3, pl2, pl1, pml_index4, pml_index3, pml_index2, pml_index1, entries);

			ulong physAddr = pl1[pml_index1].address;
			physAddr <<= 12;

			bool noPhysAlloc = cast(bool)pl1[pml_index1].noPhysAlloc;

			pl1[pml_index1].pml1e = 0;

			if (!noPhysAlloc) {
				pMem.freePage(cast(void*)physAddr);
			}

			devicePageStart += vMem.PAGE_SIZE;
		}
	}

	// sets this page table as the currently in use table
	void use(uint cpuNum)
	{
		ulong addr = cast(ulong)entries;
		addr -= VM_BASE_ADDR;

		// map in the CPU page entries
		entries[510].pml4e = (cast(pml4*)CPU_PAGETABLE_ADDR)[510].pml4e;

		//kprintfln!("entries: {x}, addr: {x}")(&entries, addr);
		asm {
			"mov %0, %%rax" :: "o" addr;
			"mov %%rax, %%cr3";
		}
	}
}

align(1) private struct pml4
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
	"d", 1, "pat", 1, "g", 1, "avl", 3, "address", 41,
	// Available Bits:
	"noPhysAlloc", 1,	// when set: do NOT free the physical page
	"available", 9,
	// ---------------
	"nx", 1));
}

//alias pml4* PageTable;


// Entry point in to the page table
pml4[] pageLevel4;

// The kernel will always live in upper memory (across all page tables)
// to accomplish this, we'll put it in the SAME pageLevel3 for every
// table.  To do this we must keep track of the location of that level3
// in a variable called kernel_mapping
pml3[] kernel_mapping;

	kmutex vMemMutex;

	void install()
	{
		// This is not locked because the main cpu should run this before
		// any other cpus are initialized (it sort of has to be that way)

		// Allocate the physical page for the top-level page table.
	 	pageLevel4 = (cast(pml4*)pMem.requestPage())[0 .. 512];

		auto kernel_size = (cast(ulong)pageLevel4.ptr / PAGE_SIZE);

		global_mem_regions.kernel.physical_start = cast(ubyte*)0x100000;
		global_mem_regions.kernel.virtual_start = cast(ubyte*)0xffffffff80000000;
		global_mem_regions.kernel.length = kernel_size * PAGE_SIZE;

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

		pml3[] pageLevel3 = (cast(pml3*)pMem.requestPage())[0 .. 512];


		pageLevel3[] = pml3.init;
		// Make sure we know where the kernel is living FO REALS!
		kernel_mapping = pageLevel3[];

		// Set the 511th entry of level 4 to a level 3 entry
		pageLevel4[511].pml4e = cast(ulong)pageLevel3.ptr;
		// Set correct flags, present, rw, usable
		pageLevel4[511].pml4e |= 0x7;

		// Create a level 2 entry
		pml2[] pageLevel2 = (cast(pml2*)pMem.requestPage())[0 .. 512];


		pageLevel2[] = pml2.init;

		// Set the 511th entry of level 3 to a level 2 entry
		pageLevel3[510].pml3e = cast(ulong)pageLevel2.ptr;
		// Set correct flags, present, rw, usable
		pageLevel3[510].pml3e |= 0x7;

		// forward reference a page level 1 array
		pml1[] pageLevel1;

		auto addr = 0x00; 		// Current addr

		int i, j;

		for(i = kernel_size-1, j = 0; i >= 0; j++) {
			// Make some page table entries
			pageLevel1 = (cast(pml1*)pMem.requestPage())[0 .. 512];

			// Set pml2e to the pageLevel 1 entry
			pageLevel2[j].pml2e = cast(ulong)pageLevel1.ptr;
			pageLevel2[j].pml2e |= 0x7;

			// Now map all the physical addresses :)  YAY!
			for(int z = 0; z < 512 && i >= 0; z++, i--) {
				pageLevel1[z].pml1e = addr;
				pageLevel1[z].pml1e |= 0x87;
				//pageLevel1[z].us = 1;
				addr += 4096;
			}
		}

		// Lets map in all of our phyiscal memory here, just so we can write to it
		// without a chicken and the egg problem...
		mapRam(pageLevel3);

		// establish the kernel mapped area (after RAM mapping)
		// this is for devices and bios regions
		global_mem_regions.kernel_mapped.virtual_start = global_mem_regions.system_memory.virtual_start + global_mem_regions.system_memory.length;
		global_mem_regions.kernel_mapped.length = 0;

		// the physical start of the kernel mapping is not known
		global_mem_regions.kernel_mapped.physical_start = global_mem_regions.kernel_mapped.virtual_start;

		kdebugfln!(DEBUG_PAGING, "virtual mapping starts: {x}")(global_mem_regions.kernel_mapped.virtual_start);


		kdebugfln!(DEBUG_PAGING, "kernel_size in pages = {}")(kernel_size);
		kdebugfln!(DEBUG_PAGING, "kernel_size in bytes = {}")(kernel_size * PAGE_SIZE);
		kdebugfln!(DEBUG_PAGING, "PageLevel 4 addr = {}")(pageLevel4.ptr);
		kdebugfln!(DEBUG_PAGING, "Pagelevel 3 addr = {}, {x}")(pageLevel3.ptr, pageLevel4[511].pml4e);
	    kdebugfln!(DEBUG_PAGING, "Pagelevel 2 addr = {}, {x}")(pageLevel2.ptr, pageLevel3[510].pml3e);
		kdebugfln!(DEBUG_PAGING, "Pagelevel 1 addr = {x}")(pageLevel2[0].pml2e);

		//pml1[] tmp = (cast(pml1*)(pageLevel2[1].pml2e - 0x7))[0 .. 512];

		//kdebugfln!(DEBUG_PAGING, "Page address: {x}")(tmp[0].pml1e);

		asm {
			"mov %0, %%rax" :: "o" pageLevel4.ptr;
			"mov %%rax, %%cr3";
		}

		// And now, for benefit of great gods in sky, we add VM_BASE_ADDR to
		// pageLevel4.ptr so that the CPU does't fail when trying to read a physical
		// address!
		pageLevel4 = (cast(pml4*)(cast(void*)pageLevel4.ptr + VM_BASE_ADDR) )[0 .. 512];

		pageLevel3 = getPml3(pageLevel4.ptr, 511)[0..511];

		kdebugfln!(DEBUG_PAGING, "Done Mapping ... {}")(pageLevel3[0].present);
	}

	// this will return the phyiscal address linked to the virtual address
	void* translateAddress(void* virtAddress)
	{
		pml3* pl3;
		pml2* pl2;
		pml1* pl1;

		long pml_index4;
		long pml_index3;
		long pml_index2;
		long pml_index1;

		retrievePageEntries(virtAddress, pl3, pl2, pl1, pml_index4, pml_index3, pml_index2, pml_index1);

		if (pl1 !is null)
		{
			ulong physAddr = pl1[pml_index1].address;
			physAddr <<= 12;

			return cast(void*)physAddr;
		}
	}

	// install kernel stack at KERNEL_STACK - PAGE_SIZE
	void installStack()
	{
		void* stack;

		pml1* pl1;
		pml2* pl2;
		pml3* pl3;

		long pml_index4;
		long pml_index3;
		long pml_index2;
		long pml_index1;

		void* virtualAddress;

		// Install the User Stack.
		// This stack is used by the environment.
		// This stack is switched to the register stack, and then to the kernel stack
		// during a context switch.

		// NOTE: we do this first to ensure that pl4[510] gets user mode privileges.
		// NOTE: no pages are mapped, we just ensure the page table can reach it for later
		// mapping during an environment spawn.

		// This is only 8KB

		/*virtualAddress = cast(void*)(ENVIRONMENT_STACK - (ENVIRONMENT_STACK_PAGES * PAGE_SIZE));
		while (virtualAddress != cast(void*)ENVIRONMENT_STACK)
		{
			allocateUserPageEntries(virtualAddress, pl3, pl2, pl1, pml_index4, pml_index3, pml_index2, pml_index1);

			kprintfln!("estack: {x} {} {} {} {}")(virtualAddress, pml_index4, pml_index3, pml_index2, pml_index1);

			// we reserve this page, but keep the page table entries leading to it.
			pl1[pml_index1].pml1e = 0;

			virtualAddress += PAGE_SIZE;

		}*/

		// Install the Kernel Stack.
		// This stack is used when the kernel is trapped.
		// Once the scheduler is running, the temp stack is no longer used.

		// This is only 4KB

		virtualAddress = cast(void*)(KERNEL_STACK - (KERNEL_STACK_PAGES * PAGE_SIZE));

		while (virtualAddress != cast(void*)KERNEL_STACK)
		{
			// allocate pages in memory
			stack = pMem.requestPage();

			allocateKernelPageEntries(virtualAddress, pl3, pl2, pl1, pml_index4, pml_index3, pml_index2, pml_index1);

			//kprintfln!("kstack: {x} {} {} {} {}")(virtualAddress, pml_index4, pml_index3, pml_index2, pml_index1);

			pl1[pml_index1].pml1e = (cast(ulong)stack) | 0x87;

			virtualAddress += PAGE_SIZE;
		}

		// Install the Register Stack.
		// This stack is used by the context switcher.
		// Simply contains the information necessary to switch registers.

		// NOTE: no newly allocated pages mapped, only ensuring the page table entries exist in the kernel.

		// This is only 4KB

		/*
		virtualAddress = cast(void*)(REGISTER_STACK - (REGISTER_STACK_PAGES * PAGE_SIZE));
		while (virtualAddress != cast(void*)REGISTER_STACK)
		{
			allocateKernelPageEntries(virtualAddress, pl3, pl2, pl1, pml_index4, pml_index3, pml_index2, pml_index1);

			kprintfln!("rstack: {x} {} {} {} {}")(virtualAddress, pml_index4, pml_index3, pml_index2, pml_index1);

			// it initially is mapped to the kernel stack for kernel interrupts
			pl1[pml_index1].pml1e = (cast(ulong)stack) | 0x87;

			virtualAddress += PAGE_SIZE;

		}*/

		return ErrorVal.Success;
	}

	private void mapRam(ref pml3[] pageLevel3)
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
			pageLevel2 = (cast(pml2*)pMem.requestPage())[0 .. 512];

			pageLevel2[] = pml2.init;
			pageLevel3[k].pml3e = cast(ulong)pageLevel2.ptr;
			pageLevel3[k].pml3e |= 0x7;

			for(int j = 0; i <= pageLimit && j < 512; i += 512, j++)
			{
				// Make some page table entries
				pageLevel1 = (cast(pml1*)pMem.requestPage())[0 .. 512];

				// Set pml2e to the pageLevel 1 entry
				pageLevel2[j].pml2e = cast(ulong)pageLevel1.ptr;
				pageLevel2[j].pml2e |= 0x7;

				// Now map all the physical addresses :)  YAY!
				for(int z = 0; z < 512; z++) {
					pageLevel1[z].pml1e = addr;
					pageLevel1[z].pml1e |= 0x87;
					//pageLevel1[z].us = 1;
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
	ErrorVal mapRange(ubyte* physicalRangeStart, ulong physicalRangeLength, out ubyte* virtualRangeStart)
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

		kdebugfln!(DEBUG_PAGING, "start: {} {} {}")(virtualRangeStart, global_mem_regions.kernel_mapped.virtual_start, pMem.mem_size);
		// get the initial page tables to alter

		// increment the kernel mapping region
		global_mem_regions.kernel_mapped.length += physicalRangeLength;

		pml3* pl3;
		pml2* pl2;
		pml1* pl1;

		long pml_index4;
		long pml_index3;
		long pml_index2;
		long pml_index1;

		// get the initial page table entry to set, allocating page tables as necessary
		allocateUserPageEntries(virtualRangeStart, pl3, pl2, pl1, pml_index4, pml_index3, pml_index2, pml_index1);

		//retrievePageEntries(virtualRangeStart, pl3, pl2, pl1, pml_index4, pml_index3, pml_index2, pml_index1);

		pl2 = getPml2(pl3, pml_index3);
		pl1 = getPml1(pl2, pml_index2);

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

					pl2 = getPml2(pl3, pml_index3);
					if (pl2 is null)
					{
						pl2 = allocatePml2(pl3, pml_index3);
					}
				}

				pl1 = getPml1(pl2, pml_index2);
				if (pl1 is null)
				{
					pl1 = allocatePml1(pl2, pml_index2);
				}
			}
		}

		kdebugfln!(DEBUG_PAGING, "virtual Start: {x} for length: {}")(virtualRangeStart, physicalRangeLength);

		vMemMutex.unlock();
		return ErrorVal.Success;
	}

	// Function to get a physical page of memory and map it in to virtual memory
	// Returns: 1 on success, -1 on failure
	ErrorVal getPage(bool usermode)(out void* vm_address) {

		//return ErrorVal.Success;
		vMemMutex.lock();

		vm_address = global_mem_regions.kernel.virtual_start + global_mem_regions.kernel.length;

		ulong vm_addr_long = cast(ulong)vm_address;
		//kprintfln!("ptr: vm_address: {}")(vm_address);
		kdebugfln!(DEBUG_PAGING, "The kernel end page addr in physical memory = {x}")(vm_addr_long);

		// Make sure we know where the end of the kernel now is

		ulong vm_addr = vm_addr_long;

		// Arrays for later traversal
		pml3* pl3;
		pml2* pl2;
		pml1* pl1;

		long pml_index1;
		long pml_index2;
		long pml_index3;
		long pml_index4;

		retrievePageEntries(vm_address,pl3,pl2,pl1,pml_index4, pml_index3, pml_index2, pml_index1);

		if (pl1 !is null)
		{
			if (pl1[pml_index1].present)
			{
				vMemMutex.unlock();
				return ErrorVal.PageMapError;
			}
		}

		allocatePageEntries!(usermode)(vm_address,pl3,pl2,pl1,pml_index4, pml_index3, pml_index2, pml_index1);

		// Request a page of physical memory
		auto phys = pMem.requestPage();

		static if (usermode)
		{
			kdebugfln!(DEBUG_PAGING, "physical address: {}")(phys);
		}

		pl1[pml_index1].pml1e = cast(ulong)phys;
		pl1[pml_index1].pml1e |= 0x87;
		pl1[pml_index1].us = usermode;


		// increase size of kernel map
		global_mem_regions.kernel.length += PAGE_SIZE;

		vMemMutex.unlock();

		// The page table puts the lotion on its skin or it gets the hose again...
		return ErrorVal.Success;
	}

	alias getPage!(false) getKernelPage;
	alias getPage!(true) getUserPage;

	// free_page(void* pageAddr) -- this function will free a virtual page
	// by setting its available bit
	ErrorVal freePage(void* pageAddr) {

		vMemMutex.lock();

		// Step 1: Traverse page table
		// Step 2: Set call free_phys_mem with physical address
		// Step 3: Reset present bit on free'd page
		// Step 4: profit

		// Shift the page address right 12 bits (skip the crap)

		// And it to get the index in to the level 4

		pml3* pl3;
		pml2* pl2;
		pml1* pl1;

		long pml_index4;
		long pml_index3;
		long pml_index2;
		long pml_index1;

		retrievePageEntries(pageAddr, pl3, pl2, pl1, pml_index4, pml_index3, pml_index2, pml_index1);

		if (pl1 is null)
		{
			// this virtual address is invalid
			vMemMutex.unlock();
			return ErrorVal.BadInputs;
		}

		// Step 2: Set call free_phys_mem with physical address
		pMem.freePage(cast(void*)(pl1[pml_index1].pml1e & ~0x87));

		// Step 3: Reset present bit on free'd page
		// Now lets set the page as absent in virtual memory :)
		pl1[pml_index1].pml1e &= ~0x1;



		// Step 4: profit?!?!




		vMemMutex.unlock();


		return ErrorVal.Success;
	}

	private void retrievePageEntries(void* virtual_address, out pml3* pl3, out pml2* pl2, out pml1* pl1, out long pml_index4, out long pml_index3, out long pml_index2, out long pml_index1, pml4* pl4 = pageLevel4.ptr)
	{
		ulong v_address = (cast(ulong)virtual_address) >> 12;

		pml_index1 = v_address & 0x1FF;

		v_address >>= 9;
		pml_index2 = v_address & 0x1FF;

		v_address >>= 9;
		pml_index3 = v_address & 0x1FF;

		v_address >>= 9;
		pml_index4 = v_address & 0x1FF;

//		kdebugfln!(DEBUG_PAGING | true, " rPE: {} {} {} {}")(pml_index4, pml_index3, pml_index2, pml_index1);

		// Step 1: Traversing the page table

		pl3 = getPml3(pl4, pml_index4);
		if (pl3 is null)
		{
			// this virtual address has not been mapped
			pl2 = null;
			pl1 = null;
			return;
		}

		pl2 = getPml2(pl3, pml_index3);
		if (pl2 is null)
		{
			// this virtual address has not been mapped
			pl1 = null;
			return;
		}

		pl1 = getPml1(pl2, pml_index2);
	}

	private ErrorVal allocatePageEntries(bool usermode)(void* virtualAddress, out pml3* pl3, out pml2* pl2, out pml1* pl1, out long pml_index4, out long pml_index3, out long pml_index2, out long pml_index1, pml4* pl4 = pageLevel4.ptr)
	{
		retrievePageEntries(virtualAddress, pl3, pl2, pl1, pml_index4, pml_index3, pml_index2, pml_index1, pl4);

		if (pl3 is null)
		{
			// need to allocate page level 3 before we continue
			pl3 = allocatePml3(pl4, pml_index4, usermode);
			//kprintfln!("need p3")();
		}

		if (pl2 is null)
		{
			// need to allocate page level 2 before we continue
			pl2 = allocatePml2(pl3, pml_index3, usermode);
			//kprintfln!("need p2")();
		}

		if (pl1 is null)
		{
			// need to allocate page level 1 before we continue
			pl1 = allocatePml1(pl2, pml_index2, usermode);
			//kprintfln!("need p1")();
		}

		return ErrorVal.Success;
	}

	alias allocatePageEntries!(true) allocateUserPageEntries;
	alias allocatePageEntries!(false) allocateKernelPageEntries;


	// These spawn functions basically create a new pmlX[], and save us from having
	// to retype the two lines of code every time.  Yay code reuse!?
	private pml3[] spawnPml3() {
		pml3[] pl3 = (cast(pml3*)(pMem.requestPage() + VM_BASE_ADDR))[0 .. 512];
		pl3[] = pml3.init;

		return pl3[];
	}


	private pml2[] spawnPml2() {
		pml2[] pl2 = (cast(pml2*)(pMem.requestPage() + VM_BASE_ADDR))[0 .. 512];
		pl2[] = pml2.init;

		return pl2[];
	}

	private pml1[] spawnPml1() {
		pml1[] pl1 = (cast(pml1*)(pMem.requestPage() + VM_BASE_ADDR))[0 .. 512];
		pl1[] = pml1.init;

		return pl1[];
	}




	private pml3* getPml3(pml4* pl4, ulong pml_index4)
	{
		ulong addr = pl4[pml_index4].address << 12;
		if (!pl4[pml_index4].present)
		{
			return null;
		}
		return cast(pml3*)((addr + VM_BASE_ADDR));
	}

	private pml2* getPml2(pml3* pl3, ulong pml_index3)
	{
		ulong addr = pl3[pml_index3].address << 12;
		if (!pl3[pml_index3].present)
		{
			return null;
		}
		return cast(pml2*)((addr + VM_BASE_ADDR));
	}

	private pml1* getPml1(pml2* pl2, ulong pml_index2)
	{
		ulong addr = pl2[pml_index2].address << 12;
		if (!pl2[pml_index2].present)
		{
			return null;
		}
		return cast(pml1*)((addr + VM_BASE_ADDR));
	}



	private pml3* allocatePml3(pml4* pl4, ulong pml_index4, bool usermode = false)
	{
		if (!pl4[pml_index4].present)
		{
			pml3[] pl3 = spawnPml3();

			with(pl4[pml_index4])
			{
				// set the whole address, which will also conveniently set the
				// first 12 flag bits to zero.
				pml4e = (cast(ulong)pl3.ptr) - VM_BASE_ADDR;

				// set initial bits
				present = true;
				rw = true;
				us = usermode;
			}

			return pl3.ptr;
		}
		ulong addr = pl4[pml_index4].pml4e;
		return cast(pml3*)((addr + VM_BASE_ADDR) & ~0x7);
	}

	private pml2* allocatePml2(pml3* pl3, ulong pml_index3, bool usermode = false)
	{
		if (!pl3[pml_index3].present)
		{
			pml2[] pl2 = spawnPml2();

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

			return pl2.ptr;
		}
		ulong addr = pl3[pml_index3].pml3e;
		return cast(pml2*)((addr + VM_BASE_ADDR) & ~0x7);
	}

	private pml1* allocatePml1(pml2* pl2, ulong pml_index2, bool usermode = false)
	{
		if (!pl2[pml_index2].present)
		{
			pml1[] pl1 = spawnPml1();

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

			return pl1.ptr;
		}
		ulong addr = pl2[pml_index2].pml2e;
		return cast(pml1*)((addr + VM_BASE_ADDR) & ~0x7);
	}



	private void mapExplicit(bool usermode)(void* virtual, void* physical, pml4* table)
	{
		pml1* pl1;
		pml2* pl2;
		pml3* pl3;

		long pml_index4, pml_index3, pml_index2, pml_index1;

		allocatePageEntries!(usermode)(virtual, pl3,pl2,pl1,pml_index4, pml_index3, pml_index2, pml_index1, table);

		//kprintfln!("mapExplicit: {x} {} {} {} {}")(virtual, pml_index4, pml_index3, pml_index2, pml_index1);

		pl1[pml_index1].pml1e = cast(ulong)physical | 0x87;
		static if (usermode)
		{
			pl1[pml_index1].us = 1;
		}
	}

	alias mapExplicit!(false) mapKernelExplicit;
	alias mapExplicit!(true) mapUserExplicit;


	// This function will set up and install the cpu page table from
	// the kernel common page table that is currently in use.
	ErrorVal installCpuPageTable(pml4* pageTable)
	{
		void* pageTablePhys = pMem.requestPage();
		pageTable = cast(pml4*)(pageTablePhys + VM_BASE_ADDR);

		// map in kernel specific mappings (level 511)
		pageTable[511] = pageLevel4[511];

		// now map in new cpu specific mappings (level 510)

		// CPU_INFO_ADDR

		// ensure there is only one page, because this code does not
		// account for more than one page... if needed, refer to stack
		// allocation for examples of how to do this
		static assert(CPU_INFO_PAGES == 1);

		// get a page, and map it into the correct address
		void* cpuInfoPage = pMem.requestPage();
		mapKernelExplicit(cast(void*)CPU_INFO_ADDR, cpuInfoPage, pageTable);

		// CPU_PAGETABLE_ADDR

		// map in the cpu's page table (pml4) structure
		mapKernelExplicit(cast(void*)CPU_PAGETABLE_ADDR, pageTablePhys, pageTable);

		// KERNEL_STACK
		void* virtualAddress = cast(void*)(KERNEL_STACK - (KERNEL_STACK_PAGES * PAGE_SIZE));

		void* stack;

		while (virtualAddress != cast(void*)KERNEL_STACK)
		{
			stack = pMem.requestPage();

			mapKernelExplicit(virtualAddress, stack, pageTable);

			virtualAddress += PAGE_SIZE;
		}

		// use the page table
		asm {
			"movq %0, %%rax" :: "o" pageTablePhys;
			"movq %%rax, %%cr3";
		}

		return ErrorVal.Success;
	}
}
