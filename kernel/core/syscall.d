// Contains the syscall implementations

module kernel.core.syscall;

import user.syscall;
import user.environment;

import kernel.environ.info;
import kernel.environ.scheduler;

import kernel.dev.console;

import kernel.mem.heap;
import kernel.mem.gib;

import kernel.core.error;
import kernel.core.kprintf;

import kernel.filesystem.ramfs;

import architecture.perfmon;
import architecture.mutex;
import architecture.cpu;
import architecture.timing;
import architecture.vm;

class SyscallImplementations {
static:
public:

	// Syscall Implementations

	SyscallError allocPage(out int ret, AllocPageArgs* params) {
		synchronized {
			Environment* current = Scheduler.current();

			if (current.alloc(params.virtualAddress, 4096, true) == ErrorVal.Fail) {
				ret = -1;
				kprintfln!("allocPage({}): FAIL")(params.virtualAddress);
				return SyscallError.Failcopter;
			}	

			ret = 0;

			return SyscallError.OK;
		}
	}

	// void exit(ulong retval)
	SyscallError exit(ExitArgs* params) {
		// Use ExitArgs* here... you won't be able to after the asm block

		// ... //

		// We need to switch to a kernel stack
		ulong stackPtr = cast(ulong)Cpu.stack;
		asm {
			mov RAX, stackPtr;
			mov RSP, RAX;
		}

		// Remove the environment from the scheduler
		ErrorVal ret = Scheduler.removeEnvironment();

		Scheduler.idleLoop();

		// You DO NOT return from exit... NEVER
		return SyscallError.OK;
	}

	// Memory manipulation system calls

	// ubyte* location = open(AddressSpace dest, ubyte* address, int mode);
	SyscallError open(out bool ret, OpenArgs* params) {
		// Map in the resource
		ret = VirtualMemory.openSegment(dest, address, mode);

		return SyscallError.OK;
	}

	// ubyte[] location = create(ulong size, int mode);
	SyscallError create(out ubyte[] ret, CreateArgs* params) {
		// Create a new resource.
		ret = VirtualMemory.createSegment(size, mode);

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
		return SyscallError.Failcopter;
	}

	// schedule(AddressSpace dest);
	SyscallError schedule(ScheduleArgs* params) {
		return SyscallError.Failcopter;
	}

	// yield(AddressSpace dest);
	SyscallError yield(YieldArgs* params) {
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
}

