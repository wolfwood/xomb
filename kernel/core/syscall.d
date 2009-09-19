// Contains the syscall implementations

module kernel.core.syscall;

import user.syscall;
import user.console;

import kernel.environ.info;
import kernel.environ.scheduler;

import kernel.dev.console;

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

	// void exit(ulong retval)
	SyscallError exit(ExitArgs* params) {
		return SyscallError.OK;
	}
}

