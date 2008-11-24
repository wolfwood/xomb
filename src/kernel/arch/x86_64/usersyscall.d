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

	const ulong RCX_ADDRESS = cast(ulong)vMem.REGISTER_STACK - 88UL;
	const ulong R11_ADDRESS = cast(ulong)vMem.REGISTER_STACK - 152UL;
	const ulong RSP_ADDRESS = cast(ulong)vMem.REGISTER_STACK - 28UL;

	pragma(msg, Itoh!(RCX_ADDRESS));
	pragma(msg, Itoh!(R11_ADDRESS));

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

		//"movq $" ~ Itoh!(RSP_ADDRESS) ~ ", %%rsp";

		// pop rcx and r11 off of register stack
		//"movq " ~ Itoa!(RCX_ADDRESS) ~ ", %%rcx" ::: "rcx";
		//"movq " ~ Itoh!(R11_ADDRESS) ~ ", %%r11" ::: "r11";

		"retq";
	}
}



