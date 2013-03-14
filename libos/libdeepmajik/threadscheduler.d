module libos.libdeepmajik.threadscheduler;

import libos.libdeepmajik.umm;
import Syscall = user.syscall;

import user.types;

// bottle for error code
import user.ipc;

const ulong ThreadStackSize = 4096;

/*

	Background:

		The XOmB kernel considers an environment (AKA process) to be an
		Address Space with an expected well-known entry point at 1GB + 16
		(address 0x40000010).  The root page table of the address space is
		stored in CPU register CR4 (as expected by the paging hardware --
		TLB), and is not otherwise stored by the kernel, due to our
		stateless design.

		Similarly, no stack is established by the kernel on behalf of the
		environment (per CPU stacks do exist, solely for use during system
		calls; in keeping with the 'stateless' theme, they are pointed to
		by the GS register which can only be modified in kernel mode, and
		not otherwise stored by the kernel).  This sparsity means that
		upon initial entry, the average program must first setup a stack
		for itself.

		Because we are lazy and value simplicity, we allocate this stack
		by creating a thread, one which is no different than any
		subsequent threads (this stands in opposition to some other OSes
		and user-level threading libraries, where the main thread is
		'special', often possessing an unbounded stack and/or terminating
		execution upon its exit, regardless of the number of other,
		non-blessed threads remaining).


	Theory of Operation:

		In general terms, a thread's state is the full CPU state while it
		is executing.  For our purposes, this state is limited to a stack
		and the registers that may be modified in user-mode, including the
		stack pointer and program counter.

		The functional task of the thread scheduler is providing
		mechanisms for the creation and destruction of thread state, along
		with restoring and preserving thread state (context switching)
		when CPUs are made available or relinquished, or when other
		threads are given a chance to run.

		The policy task of the thread scheduler is to decide when to
		request or relinquish CPUs, which thread to run when a new CPU is
		made available, and, for a preemptive scheduler, when to switch
		from the currently executing thread to another.

		The primary determinants of the of the performance (really the
		performance cost, compared to no intervention) of a thread
		scheduler [should be] the amount of state saved on a context
		switch and the freqency of context switching. Other factors
		include overhead of thread selection and requesting an CPU.
		Hardware factors that the scheduling policy may account for are
		cache affinity and proximity of peer threads if communication is
		occuring.

		Ignoring preemption for the moment, all interactions with the
		thread scheduler occur through function calls.  This is key to our
		strategy to minimize the amount of state we save and make this
		threading library fast.  We don't have to save the program
		counter, as it will be pushed on the thread's stack as the return
		address for the function call.  The majority of registers, if they
		are in use, are the responsibily if the caller to save on the
		stack.  If they aren't in use, the compiler won't bother to push
		them before the function call and there will be no overhead.
		However, there are 7 registers, including the stack pointer that
		must be saved by the callee.  These are RSP, RBP, RBX, R12, R13,
		R14, R15.  This threading library has no way to know which of
		these registers are actually in use, so we must save them all.
		The last 6 can be pushed onto the stack, meaning that the only
		piece of state that must be stored (apart from its stack) to
		resume a suspended thread is RSP.

		We store RSP along with any other scheduler metadata, such as the
		next pointer, in the XombThread struct.  Upon thread creation we
		allocate a page for the stack.  instead of allocating the
		XombThread struct seperately, we stick it at the top of the stack
		(remember, CPU stacks grow 'down'). Below that goes a 'return
		address' pointing to threadExit(), ensuring that if/when the
		thread's primary function exits, the thread will be properly
		cleaned up. Below that goes another return address pointing to the
		function indicated in thread create.  finally room for the 6
		callee saved registers is left, so that there is no difference
		between running a new thread and a one that has been suspended via
		threadYield().

		Note this theme of regularizing corner cases.  This simplifies
		code, speeds up critical paths and reduces the size of the
		programmer's mental model.

		Anyhow, now lets talk about preemption.  First off, I think that
		preemptive thread scheduling within an enviroment is a pretty
		silly idea.  It will increase overhead (though by how much remains
		to be seen) and inserting yields ensures that scheduling occurs
		between logical tasks (improving secondary effects like caching)
		and avoids holding locks while suspended.  If your code requires
		preemption for correctness you are most certainly doing it wrong.
		If preemption is 'required' for latency purposes sprinkling in
		yields or employing a task queue mechanism on top of the threading
		library are better options.

		Since we expect yields to be used in this fashion, it is important
		to have a quick exit path for the common case where the
		environement has as many threads as CPUs, making the yield as
		close to a no-op as possible if no switching is to occur.

		Many believe that we must support preemption for scheduling
		between enviroments.  One counter, if revocation is not
		immediately required, is simply to define the problem away.
		Instead of preemption, a CPU revocation message can result in a
		flag being set, and then next time a yield occurs the CPU being
		handed over, under the threat of aborting an environment that does
		not comply in a timely manner.  If true preemption is desired,
		however, the program counter (RIP) and full set of registers can
		be pushed, followed by a shim function, obeying our traditional
		yield mechanics, to restore these registers.  This again avoids
		the need to distiguish between yield and preempted threads.

		It may be desirable to expand threads beyond running a simple
		function with zero arguments. Adding arguement or employing
		delegates or closures can similarly be done using a shim function
		and storing the relevant state in the 6 register slots that will
		be popped from below the return address pointing to the shim.


	Scheduling:

		It is easy to implement a lock-free stack.  So, my plan for the
		scheduler was to use 2 stacks, one, 'head', for popping threads to
		be executed and one, 'tail', for pushing threads who have had a
		turn.  When the head queue is empty a double width atomic swap
		(x64's cmpxchg16b) can be used to switch head and tail, allowing
		dequeuing to continue.

		Fairness -- if the switch is done before pushing the retiring
		thread to tail, then the first and last thread execute once for
		every 2 executions of the other threads (draw it out with threads
		A B and C if you don't believe me :).  This might not be a big
		deal, but certainly defies the concept of fair. If the retiring
		thread is pushed to tail before the swap, then it will the first
		popped from head.  this provides fairness, in that each thread
		will get the same number of turns, but perhaps defies fairness in
		that sometimes a thread is scheduled back to back with itself,
		even when others are waiting for a turn. Currently we use the
		latter method.


	Embedding dequeue in swap:

		Dequeue must be guaranteed never to dequeue a null, as it
		dereferences this pointer immediately.  For easy correctness we
		embed a dequeue in our lockfree swap, avoiding a second null
		check, and a second atomic operation.

*/

align(1) struct XombThread {
	ubyte* rsp;

	//void *threadLocalStorage;
	//void * syscallBatchFrame;

	// Scheduler Data
	XombThread* next;

	/*
		R11 - address for the XombThread being scheduled (this)
		R10  - base address of the SchedQueue struct

		RAX - address for the XombThread pointed to by tail, belongs in R11's next pointer
	*/
	void schedule(){
		XombThread* foo = this;

		asm{
			lock;
			inc numThreads;

			//  can't seem to access 'this' from an asm block, so use a local var to get around it
			mov R11, foo;

			mov R10, [queuePtr];


		start_enqueue:
			mov RAX, [R10 + tailOffset];

		restart_enqueue:
			mov [R11 + XombThread.next.offsetof], RAX;

			// Compare RAX with m64. If equal, ZF is set and r64 is loaded into m64. Else, clear ZF and load m64 into RAX
			lock;
			cmpxchg [R10 + tailOffset], R11;
			jnz restart_enqueue;
		}
	}

	static:

	XombThread* threadCreate(void* functionPointer, ulong arg1, ulong arg2 = 0, ulong arg3 = 0, ulong arg4 = 0, ulong arg5 = 0, ulong arg6 = 0){
		XombThread* thread = threadCreate(functionPointer);

		// add another function 'return' address to the stack
		thread.rsp -= 8;
		(cast(void function()*)thread.rsp)[6] = &argShim;

		// stick args in place of the 'callee saved' registers that get
		// popped.  argShim will place these into the 'argument passing'
		// registers so that functionPointer will get the intended
		// arguments, when argShim ret's to it
		(cast(ulong*)thread.rsp)[0] = arg1;
		(cast(ulong*)thread.rsp)[1] = arg2;
		(cast(ulong*)thread.rsp)[2] = arg3;
		(cast(ulong*)thread.rsp)[3] = arg4;
		(cast(ulong*)thread.rsp)[4] = arg5;
		(cast(ulong*)thread.rsp)[5] = arg6;

		return thread;
	}

	XombThread* threadCreate(void* functionPointer){
		ubyte* stackptr = UserspaceMemoryManager.getPage(true);

		XombThread* thread = cast(XombThread*)(stackptr - XombThread.sizeof);

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
	// Based on the assumption of a fixed-size stack and that the thread struct is at the top of the stack
	XombThread* getCurrentThread(){
		XombThread* thread;

		asm{
			mov thread,RSP;
		}

		thread = cast(XombThread*)( (cast(ulong)thread & ~(UserspaceMemoryManager.stackSize-1)) | (UserspaceMemoryManager.stackSize - XombThread.sizeof) );

		return thread;
	}

	/*
		R10 - base address of the SchedQueue struct
		R11 - address for the XombThread being scheduled (this)

		RAX - address for the XombThread pointed to by tail, belongs in R11's next pointer

		R9  - temp for head of queue
		R8  - temp for tail of queue
	 */

	void threadYield(){
		asm{
			naked;

			mov R10, [queuePtr];

			//if(schedQueueRoot == schedQueueTail){return;}// super Fast (single thread) Path
			mov R9, [R10 + headOffset];
			mov R8, [R10 + tailOffset];
			cmp R8,R9;
			jne skip;
			ret;
		skip:

			// save stack ready to ret
			call getCurrentThread;
			mov R11, RAX;

			// R10 may get clobbered by function call, so load it again
			mov R10, [queuePtr];

			pushq RBX;
			pushq RBP;
			pushq R12;
			pushq R13;
			pushq R14;
			pushq R15;

			mov [R11+XombThread.rsp.offsetof],RSP;


			// stuff old thread onto schedQueueTail
		start_enqueue:
			mov RAX, [R10 + tailOffset];

		restart_enqueue:
			mov [R11 + XombThread.next.offsetof], RAX;

			lock;
			cmpxchg [R10 + tailOffset], R11;
			jnz restart_enqueue;

			jmp _enterThreadScheduler;
		}
	}


	/*
		R10 - base address of the SchedQueue struct
		R11 - address for the XombThread being enqueued (from getCurrentThread)

		RAX - address for the XombThread pointed to by tail, belongs in R11's next pointer

		RDI & RSI - location of arguments; shouldn't get clobbered, so they can be passed to Syscall.yield
	*/
	void yieldToAddressSpace(AddressSpace as, ulong idx){
		asm{
			naked;

			pushq RDI;
			pushq RSI;

			// save stack ready to ret
			call getCurrentThread;
			mov R11, RAX;

			popq RSI;
			popq RDI;

			mov R10, [queuePtr];

			pushq RBX;
			pushq RBP;
			pushq R12;
			pushq R13;
			pushq R14;
			pushq R15;

			mov [R11+XombThread.rsp.offsetof], RSP;

			// stuff old thread onto schedQueueTail
		start_enqueue:
			mov RAX, [R10 + tailOffset];

		restart_enqueue:
			mov [R11 + XombThread.next.offsetof], RAX;

			lock;
			cmpxchg [R10 + tailOffset], R11;
			jnz restart_enqueue;

			jmp Syscall.yield;
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
			assert(schedQueueStorage.head == schedQueueStorage.tail && schedQueueStorage.tail == schedQueueStorage.tail2);

			Syscall.yield(null, 2UL);
		}else{
			//freePage(cast(ubyte*)(cast(ulong)thread & (~ 0xFFFUL)));

			asm{
				jmp _enterThreadScheduler;
			}
		}
	}


	/*
		R10 - base address of the SchedQueue struct

		RAX - a snapshot of head -- if not null, the thread that will be dequeued
		RDX - a snapshot of tail

		R11 - thread pointed to by RAX's next -- proposed head for if dequeue succeeds

		RBX - proposed head for if swap succeeds
		RCX - proposed tail for if swap succeeds
	*/

	// don't call this function :) certainly, not from a thread
	void _enterThreadScheduler(){
		asm{
			naked;
			mov R10, [queuePtr];

		load_head_and_tail:
			mov RAX, [R10 + headOffset];
		load_tail:
			mov RDX, [R10 + tailOffset];

			// assumes RAX and RDX are set
		null_checks:
			// if head is not null just dequeue, no swap is needed
			cmp RAX, 0;
			jnz dequeue;

			// if tail is also null, cpu is uneeded, so yield
			// FUTURE: might decide to _create_ a thread for task queue or idle/background work
			cmp RDX, 0;
			// XXX: requires a stack?
			mov RDI, 0;
			mov RSI, 1;
			jz Syscall.yield;


			// assumes RAX and RDX are set
		swap_and_dequeue:
			// the swap
			mov RBX, RDX;
			mov RCX, RAX;

			// integrated dequeue -- if swap succeeds, replace proposed head with it's own next
			mov RBX, [RBX + XombThread.next.offsetof];

			// If RDX:RAX still equals tail:head, set ZF and copy RCX:RBX to tail:head. Else copy tail:head to RDX:RAX and clear ZF.
			lock;
			cmpxchg16b [R10];
			jnz null_checks;
			// otherwise, we suceeded in swapping AND dequeuing what was tail and is now head
			mov RAX, RDX;
			jmp enter_thread;


			// assumes RAX is set
		dequeue:
			mov R11, [RAX + XombThread.next.offsetof];

			lock;
			// if RAX still equals head, set head to R11 and set ZF; else, store head in RAX and unset ZF
			cmpxchg [R10 + headOffset], R11;
			jnz load_tail;


			// assumes RAX is set
		enter_thread:
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

	//XXX: this are dumb.  should go away when 16 byte struct alignment works properly
	void initialize(){
		queuePtr = (cast(ulong)(&schedQueueStorage) % 16) != 0 ? cast(Queue*)(cast(ulong)(&schedQueueStorage) + 8) : (&schedQueueStorage);
	}

private:
	void argShim(){
		asm{
			naked;

			// destinations are the x64 ABI's expected locations for arguments 1-6 in order
			mov RDI, R15;
			mov RSI, R14;
			mov RDX, R13;
			mov RCX, R12;
			mov R8,  RBP;
			mov R9,  RBX;

			ret;
		}
	}

	align(1) struct Queue{
		XombThread* head;
		XombThread* tail;
		XombThread* tail2;
	}

	static assert(schedQueueStorage.head.alignof >= 8);

	Queue schedQueueStorage;

	Queue* queuePtr;
	const uint headOffset = 0, tailOffset = ulong.sizeof;

	uint numThreads = 0;
}

void exit(int err){
	MessageInAbottle* bottle = MessageInAbottle.getMyBottle();

	bottle.exitCode = err;

	XombThread.threadExit();
}
