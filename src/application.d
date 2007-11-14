/** This is a test application to debug the kernel's program loading capabilities.
This is a very rudimentary application which simply moves some data into the RAX register
(effectively, passing the kernel an input variable) and calls a system call (inbterrupt 128).
*/

/**
This function is the main function of the test application. It simply
moves some attribute information into the RAX register and throws a system call interrupt (128).
*/
void main()
{
	asm
	{
		"movq $5, %%rax" ::: "rax";
		int 128;
	}
}
