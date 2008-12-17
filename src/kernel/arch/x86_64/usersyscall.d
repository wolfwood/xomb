module kernel.arch.x86_64.usersyscall; // implements the native syscall function

import kernel.arch.x86_64.vmem;
import kernel.core.util;

extern(C) long nativeSyscall(ulong ID, void* ret, void* params)
{
	// arguments for x86-64:
	// %rdi, %rsi, %rdx, %rcx, %r8, %r9
	// %rcx is also used for the return address for the syscall
	//   but we only need three arguments
	//   so these should be there!

	// I assume such in the syscall handler
	asm
	{
		naked;
		"pushq %%rcx";
		"pushq %%r11";
		"pushq %%rax";
		"syscall";
		"popq %%rax";
		"popq %%r11";
		"popq %%rcx";

		"retq";
	}
}



