module kernel.arch.x86_64.init;

import kernel.core.log;

import kernel.arch.x86_64.idt;
import kernel.arch.x86_64.gdt;
import syscall = kernel.arch.x86_64.syscall;
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

		//kprintfln!("readMSR: 0x{x}")(ret);		

		return ret;
	}

	void writeMSR(uint MSR, ulong value)
	{
		//kprintfln!("writeMSR : value : 0x{x}")(value);

		uint hi, lo;
		lo = value & 0xFFFFFFFF;
		hi = value >> 32UL;

		//kprintfln!("writeMSR : hi : 0x{x} : lo : 0x{x}")(hi,lo);

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
		kprintfln!("(15)", true)();
	}

	void install()
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
		// XXX: I want to know when this happens:
		IDT.setCustomHandler(IDT.Type.UnknownInterrupt, &ignoreHandler);

		printLogSuccess();

		printLogLine("Installing Page Tables");
		vMem.install();
		printLogSuccess();

		boot();
	}

	// common boot
	// - This function is common to all processors
	void boot()
	{
		// assign gdt
		GDT.setGDT();

		// assign idt
		IDT.setIDT();

		// assign syscall handler
		syscall.setHandler(&syscall.syscallHandler);
	}

	void ioOut(T, char[] port)(int data)
	{
		static assert (port[$-1] == 'h', "Cannot reduce port number.  Give port as a hex string.  Ex: \"64h\"");
			
		static if (is(T == ubyte) || is(T == byte))
		{		
			asm {
				"movb %0, %%al" :: "o" data;
				"outb %%al, $0x" ~ port[0..$-1];
			}
		}
		else static if(is(T == ushort) || is(T == short))
		{
			asm {
				"movw %0, %%ax" :: "o" data;
				"outw %%ax, $0x" ~ port[0..$-1];
			}
		}
		else static if(is(T == uint) || is(T==int))
		{
			asm {
				"movl %0, %%eax" :: "o" data;
				"outl %%eax, $0x" ~ port[0..$-1];
			}
		}
		else
		{
			static assert(false, "Cannot determine data type.  Usage: ioOut!(byte, \"64h\")(0xFE).  Can be: byte, short, int.");
		}
	}

	T ioIn(T, char[] port)()
	{
		static assert (port[$-1] == 'h', "Cannot reduce port number.  Give port as a hex string.  Ex: \"64h\"");
		
		T ret;	
		static if (is(T == ubyte) || is(T == byte))
		{		
			asm {
				"inb $0x" ~ port[0..$-1] ~ ", %%al; movb %%al, %0" :: "o" ret;
			}
		}
		else static if(is(T == ushort) || is(T == short))
		{
			asm {
				"inb $0x" ~ port[0..$-1] ~ ", %%ax; movw %%ax, %0" :: "o" ret;
			}
		}
		else static if(is(T == uint) || is(T==int))
		{
			asm {
				"inb $0x" ~ port[0..$-1] ~ ", %%eax; movl %%eax, %0" :: "o" ret;
			}
		}
		else
		{
			static assert(false, "Cannot determine data type.  Usage: ioIn!(byte, \"64h\")().  Can be: byte, short, int.");
		}
		return ret;
	}

	void reset()
	{
		// write 0xFE to the keyboard controller (port 64h)
		ioOut!(byte, "64h")(0xfe);
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
