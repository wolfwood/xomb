module user.nativecall; // implements the native syscall function

extern(C) int nativeSyscall(uint ID, void* ret, void* params)
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
		pushq RCX;
		pushq R11;
		pushq RAX;
		syscall;
		popq RAX;
		popq R11;
		popq RCX;

		ret;
	}
}



