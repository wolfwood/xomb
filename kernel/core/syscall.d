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
		// Use ExitArgs* here... you won't be able to after the asm block

		// ... //

		// We need to switch to a kernel stack
		ulong stackPtr = cast(ulong)Cpu.stack;
		asm {
			mov RAX, stackPtr;
			mov RSP, RAX;
		}

		exit2();


		// You DO NOT return from exit... NEVER
		return SyscallError.Failcopter;
	}

	void exit2(){
		Environment* child = Scheduler.current();
		Environment* parent = child.parent;

		// Remove the environment from the scheduler
		ErrorVal ret = Scheduler.removeEnvironment();

		if(!(parent is null)){
			parent.context.simpleExecute();
		}else{
			Scheduler.idleLoop();
		}
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

	SyscallError gibOpen(out int ret, GibOpenArgs* params){
		if(params.flags && OpenFlags.Create){
			
		}
		
		return SyscallError.OK;
	}

	SyscallError gibClose(out int ret, GibCloseArgs* params){
		return SyscallError.OK;
	}

	char[] path;
	Environment* child;
	ulong oldStack;

	SyscallError createEnv(out uint ret, CreateEnvArgs* params){
		//return SyscallError.OK;

		//Environment* child = Scheduler.newEnvironment();

		path = params.name;

		ulong stackPtr = cast(ulong)Cpu.stack;
		
		asm {
			mov RAX, RSP;
			mov oldStack, RAX;

			mov RAX, stackPtr;
			mov RSP, RAX;
		}


		child = Loader.path2env(path);


		Scheduler.current.context.install();

		asm {
			mov RAX, oldStack;
			mov RSP, RAX;
		}
		
		if(!(child is null)){
			ret = child.info.id;

			return SyscallError.OK;
		}else{
			return SyscallError.Failcopter;
		}
	}

	uint daEid;

	SyscallError yield(YieldArgs* params){

		daEid = params.eid;

		// We need to switch to a kernel stack
		ulong stackPtr = cast(ulong)Cpu.stack;
		asm {
			mov RAX, stackPtr;
			mov RSP, RAX;
		}

		yield2(daEid);


		// never gonna happen?
		return SyscallError.Failcopter;
	}

	void yield2(uint eid){
		//Scheduler.current.context.simpleExecute();

		//return SyscallError.OK;

		Environment* child = Scheduler.getEnvironmentById(eid);

		child.parent = Scheduler.current;
		child.execute();
	}

}

