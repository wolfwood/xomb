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

template contextSwitchRestore()
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

template contextSwitchStack()
{
	const char[] contextSwitchStack = `

		asm {
	
			"movq $` ~ Itoa!(vMem.REGISTER_STACK) ~ `, %%rsp";

		}

	`;
}

template contextSwitchPrepare(char[] address)
{
	const char[] contextSwitchPrepare = `

		asm {

			"movq %%rsp, %%rcx";

			"movq %0, %%rbx" :: "m" ` ~ address ~ ` : "rbx";

			// switch to stack

			"movq $` ~ Itoa!(vMem.REGISTER_STACK-8) ~ `, %%rsp";

			// stack stuff

			"pushq $0";
			"movq $` ~ Itoa!(vMem.ENVIRONMENT_STACK) ~ `, %%rax";
			"pushq %%rax";

			"pushq $((1 << 9) | (3 << 12))";
			"pushq $((9 << 3) | 3)";
			//"addq $-8, %%rsp";
			"pushq %%rbx";
			"pushq $0";
			"pushq $0";
			

		}

		mixin(contextSwitchSave!());

		asm {

			"movq %%rsp, %%rax; movq %%rax, ` ~ Itoa!(vMem.REGISTER_STACK-8) ~ `";

			"movq %%rcx, %%rsp";

		}

	`;
}

template contextStackRestore(char[] stackPtr)
{
	const char[] contextStackRestore = `
	asm 
	{
		"popq %%rcx" ::: "rcx";
		"movq %0, %%rax" :: "o" ` ~ stackPtr ~ ` : "rax";
		"movq %%rax, %%rsp" ::: "rax";
		"pushq %%rcx" ::: "rcx";
	}
	`;
}

template contextStackSave(char[] stackPtr)
{
	const char[] contextStackSave = `
	asm
	{
		"movq %%rsp, %%rax" ::: "rax";
		"movq %%rax, %0" :: "o" ` ~ stackPtr ~ ` : "rax";
	}
	`;
}
