module kernel.arch.x86_64.context;

import kernel.arch.x86_64.vmem;
import kernel.core.util;

/*

Template: contextSwitchSave, contextSwitchRestore

The following templates have been create to handle the code that is required to
context switch saves and restores.

At first we had originally tried to just create functions that could be called
for these operations however, there are number of tricky things you have to worry
about when executing this code from a function.

By doing this in templates allows us to store this code in one place and easily
call it by using an inline mixin() call.

For example:

function blah()
{
	mixin(!contextSwitchSave());

	asm { .... }

	mixin(!contextSwitchRestore());
}

*/
template contextSwitchSave()
{
	version(LDC)
	{

		const char[] contextSwitchSave = `
		asm
		{
			naked;
			pushq RAX;
			pushq RBX;
			pushq RCX;
			pushq RDX;
			pushq RSI;
			pushq RDi;
			pushq RBP;
			pushq R8;
			pushq R9;
			pushq R10;
			pushq R11;
			pushq R12;
			pushq R13;
			pushq R14;
			pushq R15;
		}
	`;
	}
	else
	{
		const char[] contextSwitchSave = `
		asm
		{
			naked;
			"pushq %%rax";
			"pushq %%rbx";
			"pushq %%rcx";
			"pushq %%rdx";
			"pushq %%rsi";
			"pushq %%rdi";
			"pushq %%rbp";
			"pushq %%r8";
			"pushq %%r9";
			"pushq %%r10";
			"pushq %%r11";
			"pushq %%r12";
			"pushq %%r13";
			"pushq %%r14";
			"pushq %%r15";
		}

	`;
	}
}

template contextSwitchRestore()
{
	version(LDC)
	{
		const char[] contextSwitchRestore = `
		asm
		{
			naked;
			popq R15;
			popq R14;
			popq R13;
			popq R12;
			popq R11;
			popq R10;
			popq R9;
			popq R8;
			popq RBP;
			popq RDI;
			popq RSI;
			popq RDX;
			popq RCX;
			popq RBX;
			popq RAX;
		}
		`;
	}
	else
	{
		const char[] contextSwitchRestore = `
		asm
		{
			naked;
			"popq %%r15";
			"popq %%r14";
			"popq %%r13";
			"popq %%r12";
			"popq %%r11";
			"popq %%r10";
			"popq %%r9";
			"popq %%r8";
			"popq %%rbp";
			"popq %%rdi";
			"popq %%rsi";
			"popq %%rdx";
			"popq %%rcx";
			"popq %%rbx";
			"popq %%rax";
		}
		`;
	}
}
/*
template contextSwitchStack()
{
	const char[] contextSwitchStack = `
		asm {

			//movq $` ~ Itoa!(vMem.REGISTER_STACK) ~ `, %%rsp;
			movq rsp, vMem.REGISTER_STACK;

		}
	`;
}
*/

// For first time execute of an environment.
// When an environment is spawned, its register stack is
//   empty.  Therefore, we should fill it so that an iretq
//   or sysretq can return to a brand new environment.
//   It should be nifty.
template contextSwitchPrepare(char[] address)
{
	version(LDC)
	{
	const char[] contextSwitchPrepare = `

		asm {
			naked;

			//"movq %%rsp, %%rcx";
			movq rcx, rsp;

			// switch to stack

			//"movq $` ~ Itoa!(vMem.REGISTER_STACK) ~ `, %%rsp";
			movq rsp, vMem.REGISTER_STACK;

			// stack stuff

			// SS
			//"pushq $((8 << 3) | 3)";
			pushq ((8 << 3) | 3);

			// RSP (of environment)
			//"movq $` ~ Itoa!(vMem.ENVIRONMENT_STACK) ~ `, %%rax";
			movq rax, vMem.ENVIRONMENT_STACK;
			//"pushq %%rax";
			pushq rax;

			// FLAGS
			//"pushq $((1 << 9) | (3 << 12))";
			pushq ((1 << 9) | (3 << 12));

			// CS
			//"pushq $((9 << 3) | 3)";
			pushq ((9 << 3) | 3);

			// RIP
			//"pushq %%rdi";
			pushq rdi;

			// EMULATE ERROR CODE, INTERRUPT VECTOR NUMBER
			//"pushq $0";
			//"pushq $0";
			pushq 0;
			pushq 0;

		}

		mixin(contextSwitchSave!());

		asm {

			//"movq %%rsp, %%rax; movq %%rax, ` ~ Itoa!(vMem.REGISTER_STACK_POS) ~ `";
			movq rax, rsp;
			movq vMem.REGISTER_STACK_POS, rax;

			//"movq %%rcx, %%rsp";
			movq rsp, rcx;

			//"ret";
			ret;

		}

		`;
	}
	else
	{
		const char[] contextSwitchPrepare = `

		asm {
			naked;

			"movq %%rsp, %%rcx";
			// switch to stack

			"movq $` ~ Itoa!(vMem.REGISTER_STACK) ~ `, %%rsp";

			// stack stuff

			// SS
			"pushq $((8 << 3) | 3)";

			// RSP (of environment)
			"movq $` ~ Itoa!(vMem.ENVIRONMENT_STACK) ~ `, %%rax";
			"pushq %%rax";

			// FLAGS
			"pushq $((1 << 9) | (3 << 12))";

			// CS
			"pushq $((9 << 3) | 3)";

			// RIP
			"pushq %%rdi";

			// EMULATE ERROR CODE, INTERRUPT VECTOR NUMBER
			"pushq $0";
			"pushq $0";
		}

		mixin(contextSwitchSave!());

		asm {

			"movq %%rsp, %%rax; movq %%rax, ` ~ Itoa!(vMem.REGISTER_STACK_POS) ~ `";
			//movq rax, rsp;
			//movq vMem.REGISTER_STACK_POS, rax;

			"movq %%rcx, %%rsp";
			//movq rsp, rcx;

			"ret";
			//ret;

		}

	`;
	}
}
