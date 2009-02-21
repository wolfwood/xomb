module kernel.arch.x86_64.pagefault;

import kernel.arch.x86_64.idt;
import config;

import kernel.dev.vga;

/* Handle faults -- the fault handler
 * This should handle everything when a page fault
 * occurs.
 */

void pageFaultHandler(InterruptStack* ir_stack) 
	{
		// First we need to determine why the page fault happened
		// This ulong will contain the address of the section of memory being faulted on
		void* addr;
		// This is the dirty asm that gets the address for us...
		if ((ir_stack.err_code & 4) == 0)
		{
			//asm { "mov %%cr2, %%rax" ::: "rax"; "movq %%rax, %0" :: "m" addr; }
		}
		// And this is a print to show us whats going on

		// Page fault error code is as follows (page 225 of AMD System docs):
		// Bit 0 = P bit - set to 0 if fault was due to page not present, 1 otherwise
		// Bit 1 = R/W bit - 0 for read, 1 for write fault
		// Bit 2 = U/S bit - 0 if fault in supervisor mode, 1 if usermode
		// Bit 3 = RSV bit - 1 if processor tried to read from a reserved field in PTE
		// Bit 4 = I/D bit - 1 if instruction fetch, otherwise 0
		// The rest of the error code byte is considered reserved

		kdebugfln!(DEBUG_PAGEFAULTS, "\n Page fault. Code = {}, IP = 0x{x}, VA = 0x{x}, RBP = 0x{x}\n")(ir_stack.err_code, ir_stack.rip, addr, ir_stack.rbp);

		if((ir_stack.err_code & 1) == 0) 
		{
			kdebugfln!(DEBUG_PAGEFAULTS, "Error due to page not present!")();
		}
		if((ir_stack.err_code & 2) != 0)
		{
			kdebugfln!(DEBUG_PAGEFAULTS, "Error due to write fault.")();
		}
		else
		{
			kdebugfln!(DEBUG_PAGEFAULTS, "Error due to read fault.")();
		}
		if((ir_stack.err_code & 4) != 0)
		{
			kdebugfln!(DEBUG_PAGEFAULTS, "Error occurred in usermode.")();
			// In this case we need to send a signal to the libOS handler
		}
		else
		{
			kdebugfln!(DEBUG_PAGEFAULTS, "Error occurred in supervised mode.")();
			// In this case we're super concerned and need to handle the fault
		}
		if((ir_stack.err_code & 8) != 0)
		{
			kdebugfln!(DEBUG_PAGEFAULTS, "Tried to read from a reserved field in PTE!")();
		}
		if((ir_stack.err_code & 16) != 0)
		{
			kdebugfln!(DEBUG_PAGEFAULTS, "Instruction fetch error!")();
		}
	}


