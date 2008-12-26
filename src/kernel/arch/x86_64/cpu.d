module kernel.arch.x86_64.cpu;

import kernel.core.log;

import kernel.arch.x86_64.idt;
import kernel.arch.x86_64.gdt;
import kernel.arch.x86_64.syscall;
import kernel.arch.x86_64.vmem;
import kernel.arch.x86_64.pagefault;
import kernel.arch.x86_64.pic;
import kernel.arch.x86_64.lapic;

import kernel.mem.pmem;

// reporting BSP readiness to scheduler
import kernel.environment.scheduler;

import multiboot = kernel.core.multiboot;

import kernel.dev.vga;

struct Cpu
{
static:

	uint numInitedCpus;		// contains the number of CPUs successfully installed.
							// differs from the MP number of cpus, as some may be defective

	// this structure provides information about the cpu
	CpuInfo* info = cast(CpuInfo*)vMem.CPU_INFO_ADDR;

	// For the CPU page, which describes the cpu at a common virtual location
	struct CpuInfo
	{
		uint ID;			// the logical id of the cpu (to XOmB)
		uint hardwareID;	// the physical id of the cpu (to hardware, localAPIC)

		vMem.pml4* pageTable;	// cpu page table, contains per cpu mappings
	}

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

	void ignoreHandler(InterruptStack* s)
	{
		kprintfln!("(15)", true)();
	}

	void install()
	{
		//This shuts off the PIT since its started by grub
		ioOut!(byte,"43h")(0x30);
		ioOut!(byte,"40h")(0x00);
		ioOut!(byte,"40h")(0x00);

		PIC.EOI(0);

		PIC.disable();

		// EOI the PIT just incase
		PIC.EOI(0);

		// must be sure
		PIC.disable();

		printLogLine("Installing GDT");
		// install the Global Descriptor Table (GDT) and the Interrupt Descriptor Table (IDT)
		GDT.install();
		printLogSuccess();

		printLogLine("Installing IDT");
		Interrupts.install(&Scheduler.schedule);
		printLogSuccess();

		printLogLine("Installing Paging Mechanism");
		Interrupts.setCustomHandler(Interrupts.Type.PageFault, &pageFaultHandler);
		// XXX: I want to know when this happens:
		Interrupts.setCustomHandler(Interrupts.Type.UnknownInterrupt, &ignoreHandler);

		printLogSuccess();

		printLogLine("Installing Page Tables");
		vMem.install();
		printLogSuccess();

		//vMem.installStack();

		// use the page tables, gdt, etc
		boot();

		// Now that page tables are implemented,
		// Map in the BIOS regions.

		Scheduler.cpuReady(0);

		multiboot.mapRegions();
	}

	// common boot
	// - This function is common to all processors
	void boot()
	{
		//kprintfln!("Setting up CPU specific pages")();

		// set the cpu's page table
		vMem.pml4* pageTable;
		// this function will set pageTable to the virtual address
		// of the page table
		vMem.installCpuPageTable(pageTable);

		//kprintfln!("install cpu page table")();

		//kprintfln!("CPU specific page table in use")();

		// we have a stack per cpu located at KERNEL_STACK
		// and we have a cpu info page located at CPU_INFO_ADDR

		// the Cpu.info structure automatically points here

		// set stuff about this specific cpu here:
		// (mapped at CPU_INFO_ADDR)
		info.ID = numInitedCpus;
		info.pageTable = pageTable;

		//kprintfln!("info set")();

		numInitedCpus++;

		//kprintfln!("cpus incremented")();

		//kprintfln!("Set up info page for CPU {}")(numInitedCpus-1);

		// assign gdt
		GDT.setGDT();

		//kprintfln!("Installed GDT")();

		// assign idt
		Interrupts.setIDT();

		//kprintfln!("Installed IDT")();

		// assign syscall handler
		Syscall.setHandler(&Syscall.syscallHandler);

		//kprintfln!("Installed SYSCALL")();
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
