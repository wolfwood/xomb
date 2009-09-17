// Contains the syscall implementations

module kernel.core.syscall;

import user.syscall;
import user.console;

struct SyscallImplementations {
static:
public:

	// Syscall Implementations

	// add two numbers, a and b, and return the result
	// ulong add(long a, long b)
	SyscallError add(out long ret, AddArgs* params) {
		ret = params.a + params.b;
		return SyscallError.OK;
	}

	SyscallError requestConsole(RequestConsoleArgs* params) {
		params.cinfo.buffer = null;
		params.cinfo.width = 80;
		params.cinfo.height = 24;
		params.cinfo.type = ConsoleType.Buffer8Char8Attr;
		return SyscallError.OK;
	}

	// void exit(ulong retval)
	SyscallError exit(ExitArgs* params) {
		return SyscallError.OK;
	}
}

