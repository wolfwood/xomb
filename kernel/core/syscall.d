// Contains the syscall implementations

module kernel.core.syscall;

import kernel.user.syscall;

struct SyscallImplementations
{

static:
public:

	// Syscall Implementations

	// add two numbers, a and b, and return the result
	// ulong add(long a, long b)
	SyscallError add(out long ret, AddArgs* params)
	{
		ret = params.a + params.b;
		return SyscallError.OK;
	}

	// void exit(ulong retval)
	SyscallError exit(ExitArgs* params)
	{

		return SyscallError.OK;
	}
}

