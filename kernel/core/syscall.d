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
	/*SyscallError close(CloseArgs* params) {
		// Unmap the resource.
		VirtualMemory.closeSegment(params.location);

		return SyscallError.Failcopter;
		}*/

	// Scheduling system calls

	// AddressSpace space = createAddressSpace();
	SyscallError createAddressSpace(out AddressSpace ret, CreateAddressSpaceArgs* params) {

		ret = VirtualMemory.createAddressSpace();

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
		// lol... do this BEFORE switching address spaces
		ulong idx = params.idx;

		if(idx == 0 || idx == 2){
			// XXX: ensure current address space is params.dest's parent
		}

		if(idx > 2){
			return SyscallError.Failcopter;
		}

		ulong physAddr;

		if(VirtualMemory.switchAddressSpace(params.dest, physAddr) == ErrorVal.Fail){
			return SyscallError.Failcopter;
		}

		Cpu.enterUserspace(idx, physAddr);
	}
}

