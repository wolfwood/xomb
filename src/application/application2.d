/** This is a test application to debug the kernel's program loading capabilities.
This is a very rudimentary application which simply moves some data into the RAX register
(effectively, passing the kernel an input variable) and calls a system call (inbterrupt 128).
*/

import user.syscall;

void main()
{

	// 1st parameter is the CPU id from 0 to numCpus - 1

	int cpuID;

	asm {

		"movq %%rsi, %0" :: "m" cpuID : "rax";

	}

 for (;;)
 {
	//grabch();
	yield();
 }

 return;
}
