/*
locks.d

implements spin locks/semaphores for the kernel.
*/

module kernel.arch.x86_64.locks;

//debugging

import kernel.dev.vga;

const int KMUTEX_UNLOCKED = 1;
const int KMUTEX_LOCKED = 0;

struct kmutex {
	int eid=0, pid=0, tid=0; // might want to know who has it...
	int lock_val = KMUTEX_UNLOCKED;
		// use this for atomic lock checks
	int num_accesses = 0; // num times accessed .
	int num_blocks = 0; // num times unsuccessful access
}

void get_kmutex(kmutex* lock){
	// why does this loop look like it does?
	// see http://en.wikipedia.org/wiki/Test_and_Test-and-set
	do {
		while (lock.lock_val == KMUTEX_LOCKED) {}
	} while (kmutex_test_and_set(&lock.lock_val) != KMUTEX_UNLOCKED);
	// if it returns _UNLOCKED then we got the lock
}

// returns true if get lock...
int get_kmutex_nowait(kmutex* lock){
	return kmutex_test_and_set(&lock.lock_val)==KMUTEX_UNLOCKED;
}

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

void release_kmutex(kmutex* lock){
	lock.lock_val = KMUTEX_UNLOCKED;
}

int test_kmutex(){
	kmutex m;
	if (m.lock_val != KMUTEX_UNLOCKED) { return -1; }

	int lv = get_kmutex_nowait(&m);
	//if (lv != KMUTEX_UNLOCKED) { return -2; }
	if (!lv) { return -2; }
	if (m.lock_val != KMUTEX_LOCKED) { return -3; }
	
	lv = get_kmutex_nowait(&m);
	//if (lv != KMUTEX_LOCKED) { return -4; }
	if (lv) { return -4; }
	if (m.lock_val != KMUTEX_LOCKED) { return -5; }
	
	release_kmutex(&m);
	if (m.lock_val != KMUTEX_UNLOCKED) {return -6; }
	
	return 0;
}

