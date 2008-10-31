// Contains the syscall implementations

module kernel.core.syscall;

import user.syscall;

import kernel.core.error;
import kernel.dev.vga;

import kernel.arch.select;

struct Syscall
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

	// void allocPage(void* virtAddr)
	SyscallError allocPage(out ulong ret, AllocPageArgs* params)
	{
		if(vMem.getUserPage(params.va) == ErrorVal.Success)
			ret = SyscallError.OK;
		else
			ret = SyscallError.Failcopter;
			
		return cast(SyscallError)ret;
	}
	
	// void exit(ulong retval)
	SyscallError exit(ExitArgs* params)
	{
		kprintfln!("WARNING: exit() not yet implemented")();
		return SyscallError.Failcopter;
	}
	
	SyscallError freePage(FreePageArgs* params)
	{	
		return SyscallError.OK;
	}
	
}
			
