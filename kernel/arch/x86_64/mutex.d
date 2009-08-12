/*
   mutex.d

   implements spin locks/semaphores for the kernel.

*/

module kernel.arch.x86_64.mutex;

struct Mutex {
	void lock() {
		// Test and Test-and-set implementation:
		while (value == Value.Locked || testAndSet(&value) == Value.Locked) {
		}
	}

	bool locked() {
		return value == Value.Locked;
	}

	void unlock() {
		value = Value.Unlocked;
	}

private:

	enum Value : int {
		Locked,
		Unlocked
	}

	Value value = Value.Unlocked;

	// RDI is the register that holds the first argument
	Value testAndSet(Value* value) {
		asm {
			naked;
			mov RAX, 0;
			xchg [RDI], RAX;
			ret;
		}
	}
}
