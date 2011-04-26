module libos.libdeepmajik.threadscheduler;

import libos.libdeepmajik.umm;
import user.syscall;

import user.environment;

const ulong ThreadStackSize = 4096;

align(1) struct XombThread {
	ubyte* rsp;
	
	//void *threadLocalStorage;
	//void * syscallBatchFrame;
	
	// Scheduler Data
	XombThread* next;
	
	void schedule(){
		XombThread* foo = this;

		asm{ 
			lock;
			inc numThreads;

			mov R11, foo;

		start_enqueue:
			// XXX: assemble warning 1
			mov RAX, [XombThread.schedQueue + schedQueue.tail.offsetof];

		restart_enqueue:
			mov [R11 + XombThread.next.offsetof], RAX;

			mov R9, R11;
			// Compare RAX with m64. If equal, ZF is set and r64 is loaded into m64. Else, clear ZF and load m64 into RAX.
			// XXX: assemble warning 2
			lock;
			cmpxchg [XombThread.schedQueue + schedQueue.tail.offsetof], R9;
			jnz restart_enqueue;
		}
	}

	static:
	
	XombThread* threadCreate(void* functionPointer){
		ubyte* stackptr = UserspaceMemoryManager.getPage(true);
	
		XombThread* thread = cast(XombThread*)(stackptr + 4096 - XombThread.sizeof);
	
		thread.rsp = cast(ubyte*)thread - ulong.sizeof;
		*(cast(ulong*)thread.rsp) = cast(ulong) &threadExit;
	
		// decrement sp and write arg
		thread.rsp = cast(ubyte*)thread.rsp - ulong.sizeof;
		*(cast(ulong*)thread.rsp) = cast(ulong) functionPointer;	

		// space for 6 callee saved registers so new threads look like any other
		thread.rsp = cast(ubyte*)thread.rsp - (6*ulong.sizeof);

		return thread;
	}

	// WARNING: deep magic will fail silently if there is no thread
	// Based on the assumption of a 4kstack and that the thread struct is at the top of the stack
	XombThread* getCurrentThread(){
		XombThread* thread;

		asm{
			mov thread,RSP;
		}
	
		thread = cast(XombThread*)( (cast(ulong)thread & ~0xFFFUL) | (4096 - XombThread.sizeof) );
	
		return thread;
	}

	void threadYield(){
		asm{
			naked;
		
			//if(schedQueueRoot == schedQueueTail){return;}// super Fast (single thread) Path
			mov R9, [XombThread.schedQueue + schedQueue.head.offsetof];
			mov R8, [XombThread.schedQueue + schedQueue.tail.offsetof];
			cmp R8,R9;
			jne skip;
			ret;
		skip:

			// save stack ready to ret

			call getCurrentThread;
			mov R11, RAX;

			pushq RBX;
			pushq RBP;
			pushq R12;
			pushq R13;
			pushq R14;
			pushq R15;

			//mov R11, thread;
			mov [R11+XombThread.rsp.offsetof],RSP;

			// swap root and tail if needed
			
			
			mov R9, [XombThread.schedQueue + schedQueue.head.offsetof];
			mov R8, 0;
			cmp R8,R9;
			jne start_enqueue;
			/*
			// RBX is callee saved for some reason
			mov RDI, RBX;

			// Compare RDX:RAX to m128. If equal, set ZF and copy RCX:RBX to m128. Otherwise, copy m128 to RDX:RAX and clear ZF.
			mov RAX, [XombThread.schedQueue + 0];
			mov RDX, [XombThread.schedQueue + 8];

			mov RBX, RDX;
			mov RCX, RAX;

			lock;
			cmpxch16b XombThread.schedQueue;
			
			mov RBX, RDI;
			*/
			mov R9, [XombThread.schedQueue + schedQueue.tail.offsetof];
			mov [XombThread.schedQueue + schedQueue.head.offsetof], R9;
			mov [XombThread.schedQueue + schedQueue.tail.offsetof], R8;
			//}
	
			//XombThread* t;
	
			//if(schedQueueRoot == null){
			//	schedQueueRoot = schedQueueTail;
			//	schedQueueTail = null;
			//}
	
			//t = schedQueueRoot;
			//schedQueueRoot = t.next;
	
			//thread.next = schedQueueTail;
			//schedQueueTail = thread;

			//asm{
			// stuff old thread onto schedQueueTail
		start_enqueue:
			mov RAX, [XombThread.schedQueue + schedQueue.tail.offsetof];

		restart_enqueue:
			mov [R11 + XombThread.next.offsetof], RAX;

			mov R9, R11;
			lock;
			cmpxchg [XombThread.schedQueue + schedQueue.tail.offsetof], R9;
			jnz restart_enqueue;


			// remove node from schedQueue.head
		start_dequeue:
			mov RAX, [XombThread.schedQueue + schedQueue.head.offsetof];

		restart_dequeue:
			mov R11, [RAX + XombThread.next.offsetof];

			lock;
			cmpxchg [XombThread.schedQueue + schedQueue.head.offsetof], R11;
			jnz restart_dequeue;


			mov RSP,[RAX+XombThread.rsp.offsetof];

			popq R15;
			popq R14;
			popq R13;
			popq R12;
			popq RBP;
			popq RBX;

			ret;
		}

		/*
			if(schedQueueRoot != null){ // Fast (multi thread) Path
			fastpath:
			// XXX: lockfree
			thread.next = schedQueueTail;
			schedQueueTail = thread;

			// XXX: lockfree
			thread.next = schedQueueRoot;
			schedQueueRoot = thread;

			asm{
			mov RSP,t.rsp;
			ret;
			}
			}else{
			// exchange Root and Tail

			asm{

			xor ECX,ECX;
			xor EBX,EBX;

			retryRootSwap:
			mov EDX:EAX, schedQueueRoot;
			cmpxchg8b schedQueueRoot;

			jnz retryRootSwap;
			}

			goto fastpath;
			}
		*/
	}


	void yieldToAddressSpace(AddressSpace as){
		asm{
			naked;
		
			// save stack ready to ret

			call getCurrentThread;
			mov R11, RAX;
		
			pushq RBX;
			pushq RBP;
			pushq R12;
			pushq R13;
			pushq R14;
			pushq R15;
		
			//mov R11, thread;
			mov [R11+XombThread.rsp.offsetof], RSP;
		
			// stuff old thread onto schedQueueTail
		start_enqueue:
			mov RAX, [XombThread.schedQueue + schedQueue.tail.offsetof];

		restart_enqueue:
			mov [R11 + XombThread.next.offsetof], RAX;

			mov R9, R11;
			lock;
			cmpxchg [XombThread.schedQueue + schedQueue.tail.offsetof], R9;
			jnz restart_enqueue;

			jmp yield;
		}
	}


	void threadExit(){
		XombThread* thread = getCurrentThread();

		asm{
			lock;
			dec numThreads;
		}

		// schedule next thread or exit hw thread or exit if no threadsleft
		if(numThreads == 0){
			assert(schedQueue.head == schedQueue.tail);

			exit(0);
		}else{
			//freePage(cast(ubyte*)(cast(ulong)thread & (~ 0xFFFUL)));
		
			asm{
				jmp _enterThreadScheduler;
			}
		}
	}

	// jmp to this function
	void _enterThreadScheduler(){
		//XXX: don't forget about Tail
		//if(schedQueueRoot == null){
		//	schedQueueRoot = schedQueueTail;
		//	schedQueueTail = null;
		//}
	
		asm{
			naked;

			// XXX: lockfree swap		
			mov RAX, [XombThread.schedQueue + schedQueue.head.offsetof];
		
			cmp RAX, 0;
			jnz start_dequeue;
			/*
			// RBX is callee saved for some reason
			mov RDI, RBX;

			// Compare RDX:RAX to m128. If equal, set ZF and copy RCX:RBX to m128. Otherwise, copy m128 to RDX:RAX and clear ZF.
			mov RAX, [XombThread.schedQueue + 0];
			mov RDX, [XombThread.schedQueue + 8];

			mov RBX, RDX;
			mov RCX, RAX;

			lock;
			cmpxch16b XombThread.schedQueue;
			
			mov RBX, RDI;
			*/
			mov RAX, [XombThread.schedQueue + schedQueue.tail.offsetof];
			mov R9, 0;
			mov [XombThread.schedQueue + schedQueue.tail.offsetof], R9;
			mov [XombThread.schedQueue + schedQueue.head.offsetof], RAX;
			

		start_dequeue:
			mov RAX, [XombThread.schedQueue + schedQueue.head.offsetof];

		restart_dequeue:
			mov R11, [RAX + XombThread.next.offsetof];

			lock;
			cmpxchg [XombThread.schedQueue + schedQueue.head.offsetof], R11;
			jnz restart_dequeue;


			mov RSP,[RAX+XombThread.rsp.offsetof];

			popq R15;
			popq R14;
			popq R13;
			popq R12;
			popq RBP;
			popq RBX;

			ret;
		}
	}

private:
	align(16) struct Queue{
		XombThread* head;
		XombThread* tail;
	}
		
	Queue schedQueue;
	uint numThreads = 0;
}
