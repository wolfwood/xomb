/*
 * cpu.d
 *
 * This module defines the interface for speaking to the Cpu
 *
 */

module architecture.cpu;

// Import Arch Modules
import kernel.arch.x86_64.core.gdt;
import kernel.arch.x86_64.core.tss;
import kernel.arch.x86_64.core.idt;
import kernel.arch.x86_64.core.paging;
import kernel.arch.x86_64.core.lapic;

// To return error values
import kernel.core.error;
import kernel.core.log;
import kernel.core.kprintf;

// For heap allocation
import kernel.mem.pageallocator;

//For System info struct?
import kernel.system.info;
import kernel.system.definitions;

import architecture.syscall;
import architecture.vm;

private {
	extern(C) {
		extern ubyte _stack;
	}
}

struct Cpu {
static:
public:

	// This module will conform to the interface
	ErrorVal initialize() {
		LocalAPIC.reportCore();

		// enable NX bit support (has to happen before any kprintf for APs)
		Cpu.writeMSR(0xC0000080, Cpu.readMSR(0xC0000080)|0x800UL);

		Log.print("Cpu: Verifying");
		Log.result(verify());

		Log.print("Cpu: Installing Page Table");
		Log.result(Paging.install());

		Log.print("Cpu: Enabling GDT");
		Log.result(GDT.install());

		Log.print("Cpu: Enabling TSS");
		Log.result(TSS.install());

		Log.print("Cpu: Enabling IDT");
		Log.result(IDT.install());

		Log.print("Cpu: Installing Stack");
		Log.result(installStack());

		asm {
			sti;
		}

		Log.print("Cpu: Enabled Interrupts");
	   	Log.result(ErrorVal.Success);

		Log.print("Cpu: Polling Cache Info");
		Log.result(getCacheInfo());

		enableFPU();

		//Log.print("Cpu: Installing System Calls");
		//Log.result(Syscall.initialize);

		return ErrorVal.Success;
	}

	uint identifier() {
		return LocalAPIC.identifier;
	}

	template ioOutMixinB(char[] port) {
		const char[] ioOutMixinB = `
		asm {
			mov AL, data;
			out ` ~ port ~ `, AL;
		}`;
	}

	template ioOutMixinW(char[] port) {
		const char[] ioOutMixinW = `
		asm {
			mov AX, data;
			mov DX, ` ~ port ~ `;
			out DX, AX;
		}`;
	}

	template ioOutMixinL(char[] port) {
		const char[] ioOutMixinL = `
		asm {
			mov EAX, data;
			mov EDX, ` ~ port ~ `;
			out DX, EAX;
		}`;
	}

	void ioOut(T)(int port, int data) {
		asm {
			mov EAX, data;
			mov EDX, port;
		}

		static if (is(T == ubyte) || is(T == byte)) {
			asm {
				out DX, AL;
			}
		}
		else static if (is(T == ushort) || is(T == short)) {
			asm {
				out DX, AX;
			}
		}
		else static if (is(T == uint) || is(T == int)) {
			asm {
				out DX, EAX;
			}
		}
		else {
			static assert (false, "Cannot determine data type.");
		}
	}

	void ioOut(T, char[] port)(int data) {
		//static assert (port[$-1] == 'h', "Cannot reduce port number");

		static if (is(T == ubyte) || is(T == byte)) {
			mixin(ioOutMixinB!(port));
		}
		else static if (is(T == ushort) || is(T == short)) {
			mixin(ioOutMixinW!(port));
		}
		else static if (is(T == uint) || is(T == int)) {
			mixin(ioOutMixinL!(port));
		}
		else {
			static assert (false, "Cannot determine data type.");
		}
	}

	template ioInMixinB(char[] port) {
		const char[] ioInMixinB = `
		asm {
			naked;
			mov DX, ` ~ port ~ `;
			in AL, DX;
			ret;
		}`;
	}

	template ioInMixinW(char[] port) {
		const char[] ioInMixinW = `
		asm {
			naked;
			mov DX, ` ~ port ~ `;
			in AX, DX;
			ret;
		}`;
	}

	template ioInMixinL(char[] port) {
		const char[] ioInMixinL = `
		asm {
			naked;
			mov EDX, ` ~ port ~ `;
			in EAX, DX;
			ret;
		}`;
	}

	T ioIn(T)(uint port) {
		// The argument is passed as RDI
		asm {
			naked;
			mov EDX, EDI;
		}

		static if (is(T == ubyte) || is(T == byte)) {
			asm {
				in AL, DX;
			}
		}
		else static if (is(T == ushort) || is(T == short)) {
			asm {
				in AX, DX;
			}
		}
		else static if (is(T == uint) || is(T == int)) {
			asm {
				in EAX, DX;
			}
		}
		else {
			static assert (false, "Cannot determine data type.");
		}

		// EAX is the return value, so this is correct
		asm {
			ret;
		}
	}

	T ioIn(T, char[] port)() {
		static if (is(T == ubyte) || is(T == byte)) {
			mixin(ioInMixinB!(port));
		}
		else static if (is(T == ushort) || is(T == short)) {
			mixin(ioInMixinW!(port));
		}
		else static if (is(T == uint) || is(T == int)) {
			mixin(ioInMixinL!(port));
		}
		else {
			static assert (false, "Cannot determine data type.");
		}
	}

	void writeMSR(uint MSR, ulong value) {
		uint hi, lo;
		lo = value & 0xFFFFFFFF;
		hi = value >> 32UL;

		asm {
			// move the MSR index to ECX
			// also move the perspective registers
			// HI -> EDX
			// LO -> EAX
			mov R15, hi;
			mov R14, lo;
			mov R13, MSR;

			mov RDX, R15;
			mov RAX, R14;
			mov RCX, R13;
			wrmsr;
		}
	}

	ulong readMSR(uint MSR) {
		ulong ret;
		ulong hi;
		ulong lo;

		asm {
			// move the MSR index to ECX
			mov ECX, MSR;

			// read MSR
			rdmsr;

			// EDX -> hi, EAX -> lo
			mov hi, EDX;
			mov lo, EAX;
		}

		ret = hi;
		ret <<= 32;
		ret |= lo;

		return ret;
	}

	/*
		added by pmcclory.
		calls cpuid with EAX set as 0x2.
		calls examineRegister on eax, ebx, and ecx to set cache info
	*/
	ErrorVal getCacheInfo() {
	     uint eax_ret;
	     uint ebx_ret, ecx_ret, edx_ret;
	     uint count;
	     uint i=0;
	     uint temp;

			 ulong saveRBX;

			 asm{movq saveRBX, RBX;}

	     eax_ret = cpuidAX(0x2);
		 ebx_ret = getBX();
		 ecx_ret = getCX();
		 edx_ret = getDX();
		 count = eax_ret & 0x000000FF;
		 //kprintfln!("count: {} eax: {x} ebx: {x} ecx: {x} edx: {x}")(count, eax_ret, ebx_ret, ecx_ret, edx_ret);
	     do {
			// In all fields, a 0 at the MSB will indicate that these are valid entries
	     	temp = (eax_ret >> 31) & 0x1;
		    if(temp == 0) {
		    	    examineRegister(eax_ret);
		    }

		    temp = (ebx_ret >> 31) & 0x1;
		    if(temp == 0) {
		    	    examineRegister(ebx_ret);
		    }

		    temp = (ecx_ret >> 31) & 0x1;
		    if(temp == 0) {
		    	    examineRegister(ecx_ret);
		    }

		    temp = (edx_ret >> 31) & 0x1;
		    if(temp == 0) {
		    	    examineRegister(edx_ret);
		    }

		    eax_ret = cpuidAX(0x2);
		 	ebx_ret = getBX();
			ecx_ret = getCX();
			edx_ret = getDX();
		    i++;
	     } while (i < count);


			 asm{movq RBX, saveRBX;}

		 return ErrorVal.Success;
	}

	ubyte* stack() {
		return _stacks[identifier];
	}

	//noreturn
  void enterUserspace(ulong idx, PhysicalAddress calleePhysAddr){
		// use CPUid as vector index and sysret to 1 GB

		// jump using sysret to 1GB for stackless entry
		ulong mySS = ((8UL << 3) | 3);
		ulong myRSP = 0;
		ulong myFLAGS = ((1UL << 9) | (3UL << 12));
		ulong myCS = ((9UL << 3) | 3);
		ulong entry = oneGB + ulong.sizeof*2;

		asm{
			movq R11, mySS;
			pushq R11;

			movq R11, myRSP;
			pushq R11;

			movq R11, myFLAGS;
			pushq R11;

			movq R11, myCS;
			pushq R11;

			movq R11, entry;
			pushq R11;

			movq RDI, idx;
			movq RSI, calleePhysAddr;

			iretq;
		}
  }

private:

	/*
	added by pmcclory.
	      loops through the bytes of the given register (should be set by a call to CPUID with EAX set to 0x2).
	      checks to see if it matches cache entries (from the Intel System programmers guide), sets appropriate fields.
	*/
	void examineRegister(uint reg) {
	     uint i;
	     uint temp;

	     for(i=0; i<4; i++) {
	     	  temp = reg >> (8 * i);
		      temp = temp & 0xFF;
		      switch(temp) {
		      		   case 0x06:
				   	System.processorInfo[Cpu.identifier].L1ICache.length = 8192;
					System.processorInfo[Cpu.identifier].L1ICache.associativity = 4;
					System.processorInfo[Cpu.identifier].L1ICache.blockSize = 32;
					break;
				   case 0x08:
				   	System.processorInfo[Cpu.identifier].L1ICache.length = 16384;
					System.processorInfo[Cpu.identifier].L1ICache.associativity = 4;
					System.processorInfo[Cpu.identifier].L1ICache.blockSize = 32;
					break;
				   case 0x09:
				   	System.processorInfo[Cpu.identifier].L1ICache.length = 16384;
					System.processorInfo[Cpu.identifier].L1ICache.associativity = 4;
					System.processorInfo[Cpu.identifier].L1ICache.blockSize = 64;
					break;
				   case 0x0A:
				   	System.processorInfo[Cpu.identifier].L1DCache.length = 8192;
					System.processorInfo[Cpu.identifier].L1DCache.associativity = 2;
					System.processorInfo[Cpu.identifier].L1DCache.blockSize = 32;
					break;
				   case 0x0C:
				   	System.processorInfo[Cpu.identifier].L1DCache.length = 16384;
					System.processorInfo[Cpu.identifier].L1DCache.associativity = 4;
					System.processorInfo[Cpu.identifier].L1DCache.blockSize = 32;
					break;
				   case 0x0D:
				   	System.processorInfo[Cpu.identifier].L1DCache.length = 16384;
					System.processorInfo[Cpu.identifier].L1DCache.associativity = 4;
					System.processorInfo[Cpu.identifier].L1DCache.blockSize = 64;
					break;
				   case 0x0E:
				   	System.processorInfo[Cpu.identifier].L1DCache.length = 24576;
					System.processorInfo[Cpu.identifier].L1DCache.associativity = 6;
					System.processorInfo[Cpu.identifier].L1DCache.blockSize = 64;
					break;
				   case 0x21:
				   	System.processorInfo[Cpu.identifier].L2Cache.length = 262144;
					System.processorInfo[Cpu.identifier].L2Cache.associativity = 8;
					System.processorInfo[Cpu.identifier].L2Cache.blockSize = 64;
					break;
				   case 0x2C:
				   	System.processorInfo[Cpu.identifier].L1DCache.length = 32768;
					System.processorInfo[Cpu.identifier].L1DCache.associativity = 8;
					System.processorInfo[Cpu.identifier].L1DCache.blockSize = 64;
					break;
				   case 0x30:
				   	System.processorInfo[Cpu.identifier].L1ICache.length = 32768;
					System.processorInfo[Cpu.identifier].L1ICache.associativity = 8;
					System.processorInfo[Cpu.identifier].L1ICache.blockSize = 64;
					break;
				   case 0x41:
				   	System.processorInfo[Cpu.identifier].L2Cache.length = 131072;
					System.processorInfo[Cpu.identifier].L2Cache.associativity = 4;
					System.processorInfo[Cpu.identifier].L2Cache.blockSize = 32;
					break;
				   case 0x42:
				   	System.processorInfo[Cpu.identifier].L2Cache.length = 262144;
					System.processorInfo[Cpu.identifier].L2Cache.associativity = 4;
					System.processorInfo[Cpu.identifier].L2Cache.blockSize = 32;
					break;
				   case 0x43:
				   	System.processorInfo[Cpu.identifier].L2Cache.length = 524288;
					System.processorInfo[Cpu.identifier].L2Cache.associativity = 4;
					System.processorInfo[Cpu.identifier].L2Cache.blockSize = 32;
					break;
				   case 0x44:
				   	System.processorInfo[Cpu.identifier].L2Cache.length = 1048576;
					System.processorInfo[Cpu.identifier].L2Cache.associativity = 4;
					System.processorInfo[Cpu.identifier].L2Cache.blockSize = 32;
					break;
				   case 0x45:
				   	System.processorInfo[Cpu.identifier].L2Cache.length = 2097152;
					System.processorInfo[Cpu.identifier].L2Cache.associativity = 4;
					System.processorInfo[Cpu.identifier].L2Cache.blockSize = 32;
					break;
				   case 0x48:
				   	System.processorInfo[Cpu.identifier].L2Cache.length = 3145728;
					System.processorInfo[Cpu.identifier].L2Cache.associativity = 12;
					System.processorInfo[Cpu.identifier].L2Cache.blockSize = 64;
					break;
				   case 0x60:
				   	System.processorInfo[Cpu.identifier].L1DCache.length = 16384;
					System.processorInfo[Cpu.identifier].L1DCache.associativity = 8;
					System.processorInfo[Cpu.identifier].L1DCache.blockSize = 64;
					break;
				   case 0x66:
				   	System.processorInfo[Cpu.identifier].L1DCache.length = 8192;
					System.processorInfo[Cpu.identifier].L1DCache.associativity = 4;
					System.processorInfo[Cpu.identifier].L1DCache.blockSize = 64;
					break;
				   case 0x67:
				   	System.processorInfo[Cpu.identifier].L1DCache.length = 16384;
					System.processorInfo[Cpu.identifier].L1DCache.associativity = 4;
					System.processorInfo[Cpu.identifier].L1DCache.blockSize = 64;
					break;
				   case 0x68:
				   	System.processorInfo[Cpu.identifier].L1DCache.length = 32768;
					System.processorInfo[Cpu.identifier].L1DCache.associativity = 4;
					System.processorInfo[Cpu.identifier].L1DCache.blockSize = 64;
					break;
				   case 0x78:
				   	System.processorInfo[Cpu.identifier].L2Cache.length = 1048576;
					System.processorInfo[Cpu.identifier].L2Cache.associativity = 4;
					System.processorInfo[Cpu.identifier].L2Cache.blockSize = 64;
					break;
				   case 0x79:
				   	System.processorInfo[Cpu.identifier].L2Cache.length = 131072;
					System.processorInfo[Cpu.identifier].L2Cache.associativity = 8;
					System.processorInfo[Cpu.identifier].L2Cache.blockSize = 64;
					System.processorInfo[Cpu.identifier].L2Cache.linesPerSector = 2;
					break;
				   case 0x7A:
				   	System.processorInfo[Cpu.identifier].L2Cache.length = 262144;
					System.processorInfo[Cpu.identifier].L2Cache.associativity = 8;
					System.processorInfo[Cpu.identifier].L2Cache.blockSize = 64;
					System.processorInfo[Cpu.identifier].L2Cache.linesPerSector = 2;
				   	break;
				   case 0x7B:
				   	System.processorInfo[Cpu.identifier].L2Cache.length = 524288;
					System.processorInfo[Cpu.identifier].L2Cache.associativity = 8;
					System.processorInfo[Cpu.identifier].L2Cache.blockSize = 64;
					System.processorInfo[Cpu.identifier].L2Cache.linesPerSector = 2;
				   	break;
				   case 0x7C:
				   	System.processorInfo[Cpu.identifier].L2Cache.length = 1048576;
					System.processorInfo[Cpu.identifier].L2Cache.associativity = 8;
					System.processorInfo[Cpu.identifier].L2Cache.blockSize = 64;
					System.processorInfo[Cpu.identifier].L2Cache.linesPerSector = 2;
				   	break;
				   case 0x7D:
				   	System.processorInfo[Cpu.identifier].L2Cache.length = 2097152;
					System.processorInfo[Cpu.identifier].L2Cache.associativity = 8;
					System.processorInfo[Cpu.identifier].L2Cache.blockSize = 64;
					break;
				   case 0x7F:
				   	System.processorInfo[Cpu.identifier].L2Cache.length = 524288;
					System.processorInfo[Cpu.identifier].L2Cache.associativity = 2;
					System.processorInfo[Cpu.identifier].L2Cache.blockSize = 64;
					break;
				   case 0x80:
				   	System.processorInfo[Cpu.identifier].L2Cache.length = 524288;
					System.processorInfo[Cpu.identifier].L2Cache.associativity = 8;
					System.processorInfo[Cpu.identifier].L2Cache.blockSize = 64;
					break;
				   case 0x82:
				   	System.processorInfo[Cpu.identifier].L2Cache.length = 262144;
					System.processorInfo[Cpu.identifier].L2Cache.associativity = 3;
					System.processorInfo[Cpu.identifier].L2Cache.blockSize = 32;
					break;
				   case 0x83:
				   	System.processorInfo[Cpu.identifier].L2Cache.length = 524288;
					System.processorInfo[Cpu.identifier].L2Cache.associativity = 8;
					System.processorInfo[Cpu.identifier].L2Cache.blockSize = 32;
					break;
				   case 0x84:
				   	System.processorInfo[Cpu.identifier].L2Cache.length = 1048576;
					System.processorInfo[Cpu.identifier].L2Cache.associativity = 8;
					System.processorInfo[Cpu.identifier].L2Cache.blockSize = 32;
					break;
				   case 0x85:
				   	System.processorInfo[Cpu.identifier].L2Cache.length = 2097152;
					System.processorInfo[Cpu.identifier].L2Cache.associativity = 8;
					System.processorInfo[Cpu.identifier].L2Cache.blockSize = 32;
					break;
				   case 0x86:
				   	System.processorInfo[Cpu.identifier].L2Cache.length = 524288;
					System.processorInfo[Cpu.identifier].L2Cache.associativity = 4;
					System.processorInfo[Cpu.identifier].L2Cache.blockSize = 64;
					break;
				   case 0x87:
				   	System.processorInfo[Cpu.identifier].L2Cache.length = 1048576;
					System.processorInfo[Cpu.identifier].L2Cache.associativity = 8;
					System.processorInfo[Cpu.identifier].L2Cache.blockSize = 64;
					break;
		      		   default:
					break;
		      }
	     }
	     return;
	}

	void enableInterrupts() {
		asm {
			sti;
		}
	}

	void disableInterrupts() {
		asm {
			cli;
		}
	}

	void enableFPU() {
		size_t cr4;

		// You can check for the FPU, or assume it
		asm {
			mov RAX, CR4;
			mov cr4, RAX;
		}

		cr4 |= 0x200;

		asm {
			mov RAX, cr4;
			mov CR4, RAX;
		}

		setFPUWord(0x37f);
	}

	void setFPUWord(ushort cw) {
		// You can check for FPU, or assume it
		ushort oldcw;
		ushort* oldcw_ptr = &oldcw;
		asm {
			fldcw cw;
			fstcw oldcw_ptr;
		}
	}

	uint cpuidDX(uint func) {
		asm {
			naked;
			mov EAX, EDI;
			cpuid;
			mov EAX, EDX;
			ret;
		}
	}

	uint cpuidAX(uint func) {
		asm {
			naked;
			mov EAX, EDI;
			cpuid;
			ret;
		}
	}

	uint cpuidBX(uint func) {
		asm {
			naked;
			mov EAX, EDI;
			cpuid;
			mov EAX, EBX;
			ret;
		}
	}

	uint cpuidCX(uint func) {
		asm {
			naked;
			mov EAX, EDI;
			cpuid;
			mov EAX, ECX;
			ret;
		}
	}

	uint getBX() {
		asm {
			naked;
			mov EAX, EBX;
			ret;
		}
	}

	uint getCX() {
		asm {
			naked;
			mov EAX, ECX;
			ret;
		}
	}

	uint getDX() {
		asm {
			naked;
			mov EAX, EDX;
			ret;
		}
	}

	private ubyte* _stacks[256];

	// Will create and install a new kernel stack
	// Note: You have to preserve the current stack
	ErrorVal installStack() {
		ubyte* stackSpace = VirtualMemory.mapStack(PageAllocator.allocPage());
		ubyte* currentStack = cast(ubyte*)(&_stack-4096);

		stackSpace[0..4096] = currentStack[0..4096];

		_stacks[identifier] = cast(ubyte*)stackSpace + 4096;
		TSS.table.RSP0 = cast(ubyte*)stackSpace + 4096;

		StackFrame* curr = null;

		asm {
			// Retrieve stack pointer, place in RAX
			mov RAX, RSP;

			// Get the page offset
			and RAX, Paging.PAGESIZE - 1;

			// Add this to the stackspace pointer
			add RAX, stackSpace;

			// Set stack pointer
			mov RSP, RAX;

			// Do the same for frame pointer
			mov RAX, RBP;
			and RAX, Paging.PAGESIZE - 1;
			add RAX, stackSpace;
			mov RBP, RAX;

			mov curr, RBP;
		}

		while(isValidAddress(cast(ubyte*)curr.next) && cast(ulong)curr.next > Paging.PAGESIZE) {
			curr.next = cast(StackFrame*)(cast(ulong)curr.next & (Paging.PAGESIZE - 1));
			curr.next = cast(StackFrame*)(cast(ulong)curr.next + stackSpace);
			curr = curr.next;
		}

		return ErrorVal.Success;
	}

	ErrorVal verify() {
		if(!(cpuidDX(0x80000001) & 0b100000000000)) {
			kprintfln!("Your computer is not cool enough. We need SYSCALL and SYSRET.")();
			return ErrorVal.Fail;
		}

		//		uint pmu_info = cpuidAX(0xA);
		//		pmu_info &= 0xFF;

		//		kprintfln!("code: {x}\n")(pmu_info);

		return ErrorVal.Success;
	}
}
