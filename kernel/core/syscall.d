// Contains the syscall implementations

module kernel.core.syscall;

import user.syscall;

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
	
class SyscallImplementations {
static:
public:

	// Syscall Implementations

	// add two numbers, a and b, and return the result
	// ulong add(long a, long b)
	SyscallError add(out int ret, AddArgs* params) {
		ret = params.a + params.b;
		return SyscallError.OK;
	}

	SyscallError requestConsole(RequestConsoleArgs* params) {
		return SyscallError.OK;
	}

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

	SyscallError fork(out int ret, ForkArgs* params) {
		return SyscallError.OK;
	}

	SyscallError open(out ubyte* ret, OpenArgs* params) {
		Gib gib = RamFS.open(params.path, params.flags, params.index);
		ret = gib.ptr;
		return SyscallError.OK;
	}

	SyscallError create(out ubyte* ret, CreateArgs* params) {
		Gib gib = RamFS.create(params.path, params.flags, params.index);
		ret = gib.ptr;
		return SyscallError.OK;
	}

	SyscallError link(out bool ret, LinkArgs* params) {
		ret = RamFS.link(params.path, params.linkpath, params.flags) == ErrorVal.Success;
		return SyscallError.OK;
	}

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

	synchronized SyscallError log(LogArgs* params){

		kprintfln!("{}")(params.string);

		return SyscallError.OK;
	}

	synchronized SyscallError dispUlong(DispUlongArgs* params){

		kprintfln!("{}")(params.val);

		return SyscallError.OK;
	}
}

