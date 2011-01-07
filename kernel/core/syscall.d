// Contains the syscall implementations

module kernel.core.syscall;

import user.syscall;
import user.environment;

import kernel.dev.console;

import kernel.core.error;
import kernel.core.kprintf;


import architecture.perfmon;
import architecture.mutex;
import architecture.cpu;
import architecture.timing;
import architecture.vm;

// temporary h4x
import kernel.core.initprocess;

	
class SyscallImplementations {
static:
public:

	// Syscall Implementations

	SyscallError allocPage(out int ret, AllocPageArgs* params) {

	assert(false);

	/*
		synchronized {
			Environment* current = Scheduler.current();

			if (current.alloc(params.virtualAddress, 4096, true) == ErrorVal.Fail) {
				ret = -1;
				kprintfln!("allocPage({}): FAIL")(params.virtualAddress);
				return SyscallError.Failcopter;
			}	

			ret = 0;

			return SyscallError.OK;
			}*/
	}

	// void exit(ulong retval)
	SyscallError exit(ExitArgs* params) {

		VirtualMemory.switchAddressSpace();

		InitProcess.enter();

		// You DO NOT return from exit... NEVER
		return SyscallError.Failcopter;
	}

	// Memory manipulation system calls

	// ubyte* location = open(AddressSpace dest, ubyte* address, int mode);
	SyscallError open(out bool ret, OpenArgs* params) {
		// Map in the resource
		ret = VirtualMemory.openSegment(params.address, params.mode);

		return SyscallError.OK;
	}

	// ubyte[] location = create(ubyte* location, ulong size, int mode);
	SyscallError create(out ubyte[] ret, CreateArgs* params) {
		// Create a new resource.
		ret = VirtualMemory.createSegment(params.location, params.size, params.mode);

		return SyscallError.Failcopter;
	}

	SyscallError map(MapArgs* params) {
		VirtualMemory.mapSegment(params.dest, params.location, params.destination, params.mode);
		return SyscallError.Failcopter;
	}

	// close(ubyte* location);
	SyscallError close(CloseArgs* params) {
		// Unmap the resource.
		VirtualMemory.closeSegment(params.location);

		return SyscallError.Failcopter;
	}

	// Scheduling system calls

	// AddressSpace space = createAddressSpace();
	SyscallError createAddressSpace(out AddressSpace ret, CreateAddressSpaceArgs* params) {

		ret = VirtualMemory.createAddressSpace();

		return SyscallError.Failcopter;
	}

	// schedule(AddressSpace dest);
	SyscallError schedule(ScheduleArgs* params) {
		return SyscallError.Failcopter;
	}

	// Userspace performance monitoring shim

	SyscallError perfPoll(PerfPollArgs* params) {
		synchronized {
			static ulong[256] value;
			static ulong numTimes = 0;
			static ulong overall;

			numTimes++;
			bool firstTime = false;

			//params.value = PerfMon.pollEvent(params.event) - params.value;
			if (numTimes == 1) {
				firstTime = true;
			}

			value[Cpu.identifier] = PerfMon.pollEvent(params.event) - value[Cpu.identifier];

			if (numTimes == 1) {
				overall = PerfMon.pollEvent(params.event);
			}
			else if (numTimes == 8) {
				overall = value[0];
				overall += value[1];
				overall += value[2];
				overall += value[3];
			}

			return SyscallError.OK;
		}
	}

	SyscallError yield(YieldArgs* params){
		if(VirtualMemory.switchAddressSpace(params.dest) == ErrorVal.Fail){
			return SyscallError.Failcopter;
		}

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

			movq RDI, 0;

			iretq;
		}

	}

	SyscallError pcmClearStats(PcmClearStatsArgs* params) {
		VirtualMemory.pcmClearStats();
		
		return SyscallError.OK;
	}
	SyscallError pcmPrintStats(PcmPrintStatsArgs* params) {
		VirtualMemory.pcmPrintStats();
		
		return SyscallError.OK;
	}
}

