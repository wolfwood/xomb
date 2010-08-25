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

// temporary h4x
import kernel.system.loader;
	
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
		Environment* child = Scheduler.current();
		Environment* parent = child.parent;

		// Use ExitArgs* before this line
		// Remove the environment from the scheduler
		ErrorVal ret = Scheduler.removeEnvironment();

		if(!(parent is null)){
			Scheduler.executeEnvironment(parent);

			// if parent exits, above might return
			Scheduler.idleLoop();
		}else{
			Scheduler.idleLoop();
		}

		// You DO NOT return from exit... NEVER
		return SyscallError.Failcopter;
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

	SyscallError createEnv(out uint ret, CreateEnvArgs* params){
		Environment* child;

		child = Loader.path2env(params.name);

		// restore current's root page table
		Scheduler.current.context.install();

		if(!(child is null)){
			child.parent = Scheduler.current;
			ret = child.info.id;

			return SyscallError.OK;
		}else{
			return SyscallError.Failcopter;
		}
	}

	SyscallError yield(YieldArgs* params){
		Environment* child = Scheduler.getEnvironmentById(params.eid);

		Scheduler.executeEnvironment(child);

		// this should only happen if the eid is for an environment that unused or in the process of exiting
		Scheduler.idleLoop();

		// never happens
		return SyscallError.OK;
	}

}

