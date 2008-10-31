module kernel.arch.x86_64.init;

import kernel.core.log;

import kernel.arch.x86_64.idt;
import kernel.arch.x86_64.gdt;

import kernel.arch.x86_64.vmem;

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
		ulong ret;
		uint hi,lo;
		asm
		{
			// move the MSR index to $ECX
			"movl %0, %%ecx" :: "o" MSR;
			// read the MSR
			"rdmsr";
			
			// HI : $EDX, LO : $EAX
			"movl %%edx, %0; movl %%eax, %1;" :: "o" hi, "o" lo;
		}

		ret = hi;
		ret <<= 32;
		ret |= lo;

		kprintfln!("readMSR: 0x{x}")(ret);		

		return ret;
	}

	void writeMSR(uint MSR, ulong value)
	{
		kprintfln!("writeMSR : value : 0x{x}")(value);

		uint hi, lo;
		lo = value & 0xFFFFFFFF;
		hi = value >> 32UL;

		kprintfln!("writeMSR : hi : 0x{x} : lo : 0x{x}")(hi,lo);

		asm
		{
			// move the MSR index to $ECX
			// also, move the value to its perspective registers
			// HI : $EDX
			// LO : $EAX
			"movl %0, %%ecx; movl %1, %%eax; movl %2, %%edx" :: "o" MSR, "o" lo, "o" hi;
			"wrmsr";
		}
	}

	void ignoreHandler(interrupt_stack* s)
	{
	}

	void boot()
	{
		printLogLine("Installing GDT");
		// install the Global Descriptor Table (GDT) and the Interrupt Descriptor Table (IDT)
		GDT.install();
		printLogSuccess();

		printLogLine("Installing IDT");
		IDT.install();
		printLogSuccess();

		printLogLine("Installing Paging Mechanism");
		IDT.setCustomHandler(IDT.Type.PageFault, &vMem.pageFaultHandler);
		IDT.setCustomHandler(IDT.Type.UnknownInterrupt, &ignoreHandler);

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
