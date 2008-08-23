module kernel.arch.x86_64.init;

import kernel.log;

import kernel.arch.select;

import idt = kernel.arch.x86_64.idt;
import gdt = kernel.arch.x86_64.gdt;

import kernel.mem.vmem;

import kernel.dev.vga;

struct Cpu
{
static:

	/**
	Gets the value of the CPUID function for a given item.  See some sort of documentation on
	how to use the CPUID function.  There's way too much to document here.

		Params:
			func = The CPUID function.
		Returns:
			The result of the CPUID instruction for the given function.
	*/
	uint cpuid(uint func)
	{
		asm
		{
			naked;
			"movl %%edi, %%eax";
			"cpuid";
			"movl %%edx, %%eax";
			"retq";
		}
	}

	void boot()
	{
		printLogLine("Installing GDT");
		// install the Global Descriptor Table (GDT) and the Interrupt Descriptor Table (IDT)
		gdt.install();
		printLogSuccess();

		printLogLine("Installing IDT");
		idt.install();
		printLogSuccess();

		printLogLine("Installing Paging Mechanism");
		idt.setCustomHandler(idt.Type.PageFault, &vMem.pageFaultHandler);
		printLogSuccess();
	}

	void validate()
	{	
		printLogLine("Validating CPU Functionality");

		if(!(cpuid(0x8000_0001) & 0b1000_0000_0000))
		{
			printLogFail();
			kprintfln!("-- Your computer is not cool enough, we need SYSCALL and SYSRET.")();
			asm { cli; hlt; }
		}
		printLogSuccess();
	}

	void disableInterrupts()
	{
		asm {
			cli;
		}
	}

	void enableInterrupts()
	{
		asm {
			sti;
		}
	}
}
