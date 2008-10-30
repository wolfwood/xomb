module kernel.arch.x86_64.init;

import kernel.log;

import kernel.arch.select;

import kernel.arch.x86_64.idt;
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
	uint cpuidDX(uint func)
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

	uint cpuidAX(uint func)
	{
		asm
		{
			naked;
			"movl %%edi, %%eax";
			"cpuid";
			"retq";
		}
	}

	uint cpuidBX(uint func)
	{
		asm
		{
			naked;
			"movl %%edi, %%eax";
			"cpuid";
			"movl %%ebx, %%eax";
			"retq";
		}
	}

	uint cpuidCX(uint func)
	{
		asm
		{
			naked;
			"movl %%edi, %%eax";
			"cpuid";
			"movl %%ecx, %%eax";
			"retq";
		}
	}

	// Will read a MSR (Model-Specific-Register)
	ulong readMSR(uint MSR)
	{
		asm
		{
			naked;
			// move the MSR index to $ECX
			"movl %%edi, %%ecx";
			// read the MSR
			"rdmsr";
			// the D ABI returns ulong as the HI in $EDX and the LO in $EAX
			// this is the same as what is set by the processor
			"retq";
		}
	}

	void writeMSR(uint MSR, ulong value)
	{
		asm
		{
			naked;
			// move the MSR index to $ECX
			"movl %%edi, %%ecx";
			// move the value to its perspective registers
			// HI : $EDX
			// LO : $EAX
			"movl %%esi, %%eax";
			"mov 32, %%cl";
			"sar %%cl, %%rsi";
			"movl %%esi, %%edx";
			"wrmsr";
			"retq";
		}
	}

	void ignoreHandler(interrupt_stack* stack)
	{
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
		idt.setCustomHandler(idt.Type.UnknownInterrupt, &ignoreHandler);

		printLogSuccess();
	}

	void validate()
	{	
		printLogLine("Validating CPU Functionality");

		// check for SYSCALL
		if(!(cpuidDX(0x8000_0001) & 0b1000_0000_0000))
		{
			printLogFail();
			kprintfln!("-- Your computer is not cool enough, we need SYSCALL and SYSRET.")();
			for(;;) {}
			asm { cli; hlt; }
		}

		// check for x2APIC
		/*if(!(cpuidCX(0x1) & (1 << 21)))
		{
			printLogFail();
			kprintfln!("-- Your computer is not cool enough, we need x2APIC")();
			for(;;) {}
			asm { cli; hlt; }
		}
		*/

		// we have total success
		printLogSuccess();
	}

	void disableInterrupts()
	{
		asm {
			naked;
			"cli";
			"retq";
		}
	}

	void enableInterrupts()
	{
		asm {
			naked;
			"sti";
			"retq";
		}
	}
}
