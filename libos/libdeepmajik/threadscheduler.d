module libos.libdeepmajik.threadscheduler;

import libos.libdeepmajik.umm;
import user.syscall;

import user.environment;

const ulong ThreadStackSize = 4096;

align(1) struct XombThread {
	//CpuContext context;
	ubyte* rsp;
	
	//void *threadLocalStorage;
	//void * syscallBatchFrame;
	
	// Scheduler Data
	XombThread* next;
	
	void schedule(){

		//dispUlong(cast(ulong)&schedQueueRoot);
		//dispUlong(cast(ulong)&schedQueueTail);

		//dispUlong(cast(ulong)schedQueueRoot);
		//dispUlong(cast(ulong)schedQueueTail);

		numThreads++;

		// XXX: lockfree
		next = schedQueueTail;
		schedQueueTail = this;

		//dispUlong(cast(ulong)schedQueueRoot);
		//dispUlong(cast(ulong)schedQueueTail);
	
		/*
			asm{
			
			// hafta preserve RBX for caller :(
			mov R9, RBX;
			
			mov RCX,this;
			mov RBX,this;
			sar	RCX, 32;
			
			
		retrySwap:
			//next = schedQueueTail;
			mov R11, schedQueTail;
			mov next, R11;
			mov 

			//schedQueueTail = this;
			
			mov R9, RBX;
		}
		}
		*/
	}
}

XombThread* schedQueueRoot = null, schedQueueTail = null;

uint numThreads = 0;

XombThread* threadCreate(void* functionPointer){
	ubyte* stackptr = getPage(true);
	
	XombThread* thread = cast(XombThread*)(stackptr + 4096 - XombThread.sizeof);
	
	thread.rsp = cast(ubyte*)thread - ulong.sizeof;
	*(cast(ulong*)thread.rsp) = cast(ulong) &threadExit;
	
	// decrement sp and write arg
	thread.rsp = cast(ubyte*)thread.rsp - ulong.sizeof;
	*(cast(ulong*)thread.rsp) = cast(ulong) functionPointer;	

	// space for 6 callee saved registers so new threads look like any other
	thread.rsp = cast(ubyte*)thread.rsp - (6*ulong.sizeof);

	//dispUlong(cast(ulong)thread);
	//dispUlong(cast(ulong)functionPointer);

	return thread;
}

// WARNING: deep magic will fail silently if there is no thread
XombThread* getCurrentThread(){
	// Based on the assumption of a 4kstack and that the thread struct is at the top of the stack

	XombThread* thread;
	//thread = ((&thread + 4095) & (~ 0xFFF)) - XombThread.sizeof;
	asm{
		mov thread,RSP;
	}
	
	thread = cast(XombThread*)( (cast(ulong)thread & ~0xFFFUL) | (4096 - XombThread.sizeof) );
	
	return thread;
}

void threadYield(){
	//if(schedQueueRoot == schedQueueTail){return;}// super Fast (single thread) Path
	
	//XombThread* thread = getCurrentThread();
	

	asm{
		naked;
		
		//if(schedQueueRoot == schedQueueTail){return;}// super Fast (single thread) Path
		mov R9, schedQueueRoot;
		mov R8, schedQueueTail;
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
		mov R9, schedQueueRoot;
		mov R8, 0;
		cmp R8,R9;
		jne noSwap;
		mov R9, schedQueueTail;
		mov schedQueueRoot, R9;
		mov schedQueueTail, R8;
	noSwap:
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
		mov R9, schedQueueTail;
		mov [R11+XombThread.next.offsetof],R9;
		mov schedQueueTail, R11;

		// remove node from schedQueueRoot
		mov R11, schedQueueRoot;
		mov R9, [R11+XombThread.next.offsetof];
		mov schedQueueRoot, R9;

		mov RSP,[R11+XombThread.rsp.offsetof];

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
		mov [R11+XombThread.rsp.offsetof],RSP;
		
		// stuff old thread onto schedQueueTail
		mov R9, schedQueueTail;
		mov [R11+XombThread.next.offsetof],R9;
		mov schedQueueTail, R11;
		

		jmp yield;
	}
}


void threadExit(){
	XombThread* thread = getCurrentThread();

	numThreads--;

	// schedule next thread or exit hw thread or exit if no threadsleft
	if(numThreads == 0){
		assert(schedQueueRoot == schedQueueTail);

		exit(0);
	}else{
		//freePage(cast(ubyte*)(cast(ulong)thread & (~ 0xFFFUL)));
		
		asm{
			jmp _enterThreadScheduler;
		}
	}
}

void yieldCPU(uint eid){
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
		mov [R11+XombThread.rsp.offsetof],RSP;

		// swap root and tail if needed
		mov R9, schedQueueRoot;
		mov R8, 0;
		cmp R8,R9;
		jne noSwap;
		mov R9, schedQueueTail;
		mov schedQueueRoot, R9;
		mov schedQueueTail, R8;
	noSwap:

		// stuff old thread onto schedQueueTail
		mov R9, schedQueueTail;
		mov [R11+XombThread.next.offsetof],R9;
		mov schedQueueTail, R11;

		jmp yield;
	}
}

// jmp to this function
void _enterThreadScheduler(){
	//XXX: don't forget about Tail
	//if(schedQueueRoot == null){
	//	schedQueueRoot = schedQueueTail;
	//	schedQueueTail = null;
	//}

	//ulong foobar;

	//dispUlong(cast(ulong)schedQueueRoot);
	//dispUlong(cast(ulong)schedQueueTail);
	
	asm{
		naked;

 		// XXX: lockfree swap		
		mov R11, schedQueueRoot;
		
		cmp R11, 0;
		jnz NoSwap;
		mov R11, schedQueueTail;
		mov RAX, 0;
		mov schedQueueTail, RAX;
	NoSwap:
		
		//mov foobar, R11;
		//}

		//dispUlong(foobar);

//asm{
		mov RAX, [R11+XombThread.next.offsetof];
		mov schedQueueRoot, RAX;

		mov RSP,[R11+XombThread.rsp.offsetof];

		popq R15;
		popq R14;
		popq R13;
		popq R12;
		popq RBP;
		popq RBX;

		ret;
	}
}
 

 align(1) struct CpuContext {
	// Registers
	long r15, r14, r13, r12, r11, r10, r9, r8;
	long rbp, rdi, rsi, rdx, rcx, rbx, rax;
	
	// special 
	long rip, rflags, rsp;

	//long cs, ss;

	// This function will dump the stack information to
	// the screen. Useful for debugging.
	/*void dump() {
		kprintfln!("Stack Dump:")();
		kprintfln!("r15:{x}|r14:{x}|r13:{x}|r12:{x}|r11:{x}")(r15,r14,r13,r12,r11);
		kprintfln!("r10:{x}| r9:{x}| r8:{x}|rbp:{x}|rdi:{x}")(r10,r9,r8,rbp,rdi);
		kprintfln!("rsi:{x}|rdx:{x}|rcx:{x}|rbx:{x}|rax:{x}")(rsi,rdx,rcx,rbx,rax);
		kprintfln!(" ss:{x}|rsp:{x}| cs:{x}")(ss,rsp,cs);
		}*/
}

