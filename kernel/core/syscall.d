// Contains the syscall implementations

module kernel.core.syscall;

import user.syscall;
import user.console;

import kernel.environ.info;
import kernel.environ.scheduler;

import kernel.dev.console;

import kernel.mem.heap;

import kernel.core.error;
import kernel.core.kprintf;

import user.ramfs;
import kernel.filesystem.ramfs;

struct SyscallImplementations {
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
		Environment* current = Scheduler.current();
		void* loc = current.mapRegion(Console.physicalLocation(), Console.width * Console.height * 2);
		params.cinfo.buffer = loc;

		params.cinfo.width = Console.width;
		params.cinfo.height = Console.height;

		params.cinfo.type = ConsoleType.Buffer8Char8Attr;
		return SyscallError.OK;
	}

	SyscallError allocPage(out int ret, AllocPageArgs* params) {
		Environment* current = Scheduler.current();

		if (current.alloc(params.virtualAddress, 4096, true) == ErrorVal.Fail) {
			ret = -1;
			kprintfln!("allocPage({}): FAIL")(params.virtualAddress);
			return SyscallError.Failcopter;
		}	

		ret = 0;
		kprintfln!("allocPage({}): OK")(params.virtualAddress);
		return SyscallError.OK;
	}

	// void exit(ulong retval)
	SyscallError exit(ExitArgs* params) {
		Scheduler.removeEnvironment();
		Scheduler.schedule();
		Scheduler.execute();

		return SyscallError.OK;
	}

	SyscallError fork(out int ret, ForkArgs* params) {
		return SyscallError.OK;
	}

	SyscallError open(out int ret, OpenArgs* params){
/*		Inode* node = RamFS.open(params.path);

		if(node !is null){
			*params.node = node;
			return SyscallError.OK;
		}else{
			return SyscallError.Failcopter;
		}*/
		return SyscallError.Failcopter;
	}
}

