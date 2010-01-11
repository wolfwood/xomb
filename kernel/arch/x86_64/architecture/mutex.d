/*
   mutex.d

   implements spin locks/semaphores for the kernel.

*/

module architecture.mutex;

struct Mutex {
	void lock() {
		// Test and Test-and-set implementation:
		do {
			while (value == Value.Locked) {
				asm {
					// The following should compile into a 'PAUSE' instruction
					// This will hint to the processor that this is a spinlock
					// This is for performance and power saving
					rep;
					nop;
				}
			}
		} while (testAndSet(&value) != Value.Unlocked);
	}

	bool locked() {
		return value == Value.Locked;
	}

	void unlock() {
		value = Value.Unlocked;
	}

	bool hasLock() {
		return value == Value.Locked;
	}

	Value value = Value.Unlocked;

private:

	enum Value : long {
		Locked = 0,
		Unlocked = 1,
	}

	// RDI is the register that holds the first argument
	Value testAndSet(Value* value) {
		asm {
			naked;
			mov RAX, Value.Locked;
			xchg [RDI], RAX;
			ret;
		}
	}
}

static assert (Mutex.sizeof == 8, "Mutex is not 8 bytes");
