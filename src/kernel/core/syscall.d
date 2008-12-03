// Contains the syscall implementations

module kernel.core.syscall;

import user.syscall;

import kernel.core.error;
import kernel.dev.vga;

import kernel.arch.vmem;

import kernel.environment.scheduler;

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

		Scheduler.exit();		

		return SyscallError.OK;
	}
	
	SyscallError freePage(FreePageArgs* params)
	{	
		return SyscallError.OK;
	}

  	SyscallError yield(YieldArgs* params) {
		Scheduler.yield();
		
		return SyscallError.OK;
      	}

	SyscallError echo(EchoArgs* params) {
		Console.printString(params.str, "");
		return SyscallError.OK;
	}
}
			
