/*
locks.d

implements spin locks/semaphores for the kernel.
*/

module kernel.arch.x86_64.locks;

const int KMUTEX_UNLOCKED = 1;
const int KMUTEX_LOCKED = 0;

// (re)locks lock_val and returns current lock_val
int kmutex_test_and_set(int* lock_val_p){
	int check = KMUTEX_LOCKED;
	volatile asm{
		"xchg (%%rax), %%rbx" 
		: "=b" check 
		: "a" lock_val_p, "b" check 
		: ;
	}
	return check;
}
