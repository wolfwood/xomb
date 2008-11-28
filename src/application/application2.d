/** This is a test application to debug the kernel's program loading capabilities.
This is a very rudimentary application which simply moves some data into the RAX register
(effectively, passing the kernel an input variable) and calls a system call (inbterrupt 128).
*/

import user.syscall;

void main()
{

 for (;;)
 {
// exit(0);
//  yield();
	int i=1;
	i--;
	int p=3;
	p = 3 / i; 
 }

 return;
}
