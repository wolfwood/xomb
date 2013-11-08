module libos.libdeepmajik.interrupthandler;

import libos.libdeepmajik.threadscheduler;

import libos.console;
import user.activation;
import user.types;
import util;

import user.environment;

struct Handler{
	static:
	bool register( ulong id, void function() fun){
		// request interrupt from init
		bool ret = register_helper(id);

		// thread is resumed when we hear back

		if(ret){
			// do it
			handlers[id] = fun;
		}

		return ret;
	}

	/* only returns if reservation fails locally, otherwise control
		 returns from reservation_response handler
	 */
	bool register_helper(ulong id){
		asm{
			naked;

			// check if reservation is taken (or has an outstanding request)
			mov R10, [reservation_ptr];
			mov AL, 0;
			mov BL, 1;
			cmpxchg [R10 + RDI], BL;
			jz keepgoing;

			// --- error, interrupt is already reserved ---
			mov RAX, 0; // false
			ret;

		keepgoing:
			// save argument so it isn't wiped by fucntion call
			pushq RDI;

			call XombThread.getCurrentThread;

			// restore argument to more convenient location
			popq R11;

			// save stack ready to ret
			pushq RBX;
			pushq RBP;
			pushq R12;
			pushq R13;
			pushq R14;
			pushq R15;

			mov [RAX+XombThread.rsp.offsetof],RSP;

			// save thread somewhere
			mov R10, [b_ptr];
			mov [R10 + R11 * 8], RAX;

			// upcall to parent
			mov RDI, Syscall.StacklessYieldID;
			mov RSI, 0;
			mov RDX, UpcallIndex.InterruptReserve;

			// payload
			mov R8, R11;

			syscall;
		}
	}

	/*
		--yield args --
		RDI - syscall ID, always == StacklessYieldID -> becomes Upcall Vector ID
		RSI - destination AddressSpace virtual address -> source AdressSpace physical address
		RDX - the upcall vector ID to use

		-- traditional payload args - untouched --
		RCX - XXX see below
		R8 - Interrupt #
		R9 - payload

		-- Remaining args --
		R10 - shadow copy of RDX

		-- clobbered registers --
		RCX - clobberd by syscall instruction
		R11 - clobberd by syscall instruction
	*/

	/*
		R11 - base address for mapped in child process root page tables
		R12 - address of the currently investigated child
		R13 - index of child
		R14 - mask for address field of Page Table Entry
		R15 - base of constructed address for return value
	*/

	void reservation_handler(){
		asm{
			naked;

			// find child
			mov R11, base_addr;
			mov R13, 0;
			mov R14, 0xFFFFFFFFFF000;
			mov R15, base_addr2;
		loop:
			add R13, 1; // increment

			mov R12, [R11+ R13*8]; // read a phys addr

			and R12, R14;

			cmp R12, RSI;

			jnz loop;

			// this is the child addr
			mov RSI, R13;
			sal RSI, 12;
			or RSI, R15;

			/*
				at this point:
				RSI - child addr
				R8 - still the interrupt #
			*/

			// --- request processing ---

			// check if reservation is taken (or has an outstanding request)
			mov R10, [reservation_ptr];
			mov AL, 0;
			mov BL, 1;
			cmpxchg [R10 + R8], BL;
			jz reserve_it;

			// already reserved, deny request
			mov RDX, UpcallIndex.InterruptResponse;
			mov R9, 0; // denied
			// RSI from search above

			jmp reply;

		reserve_it:

			// remember which child requested for later routing
			mov R10, [c_ptr];
			mov [R10 + R8*8], RSI;
		}
		version(INIT){
			asm{
				mov RDX, UpcallIndex.InterruptResponse;
				// RSI from search above
				mov R9, 1; // success
			}
		}else{
			asm{
				mov RDX, UpcallIndex.InterruptReserve;
				mov RSI, 0;
				// no R9 payload
			}
		}
		asm{
		reply:
			// respond
			mov RDI, Syscall.StacklessYieldID;

			syscall;
		}
	}

	void response_handler(){
		asm{
			naked;

			// make sure this interrupt was reserved
			mov R10, [reservation_ptr];
			mov BL, [R10 + R8];
			cmp BL, 1;
			je noerror;

			/* no such outstanding reservation... pass control to thread
				 scheduler, because an error IPC message is kind of pointless
			 */
			jmp XombThread._enterThreadScheduler;

		noerror:
			// --- if affirmative, complete reservation, else remove ---
			cmp R9, 0;
			je rollback;

			mov BL, 2;
			jmp setreservation;

		rollback:
			mov BL, 0;

		setreservation:
			// R10 from above
			mov [R10 + R8], BL; // doesn't need to be atomic, should only get one reply

			// --- check if response is for me ---
			mov R10, [b_ptr];
			mov R11, [R10 + R8 * 8];
			cmp R11, 0;
			je notlocal;
			// response is for us, return to thread

			// XXX: wipe save spot?

			jmp local_response_handler; // stackless function call

			// else pass to appropriate child
		notlocal:
			// get appropriate child from prior save
			mov R10, [c_ptr];
			mov RSI, [R10 + R8*8];

			mov RDX, UpcallIndex.InterruptResponse;
			// R8 and R9 are untouched

			mov RDI, Syscall.StacklessYieldID;

			syscall;
		}
	}

	void local_response_handler(){
		asm{
			naked;
			// payload is return value
			mov RAX, R9;

			// use interrupt number to get thread
			mov R10, [b_ptr];
			mov R12, [R10 + R8 * 8];

			// restore thread
			mov RSP, [R12+XombThread.rsp.offsetof];

			popq R15;
			popq R14;
			popq R13;
			popq R12;
			popq RBP;
			popq RBX;

			ret;
		}
	}

  void report_handler(){
		// XXX check if interrupt belongs to one of my children

		// XXX else pass to parent
	}

  void dispatch_handler(){
		// XXX check if interrupt belongs to me

		// XXX else pass to appropriate child
	}

	// this function MUST not return
	void interrupt(){
		asm{
			naked;


			mov R15, [RSI + ActivationFrame.act.stash.intNumber.offsetof];
			mov R11, [a_ptr];

			mov R14, [R11 + R15 * 8];

			//if(handlers[activation.act.stash.intNumber] !is null){
			cmp R14, 0;
			je resume;
			//	handlers[activation.act.stash.intNumber]();
			jmp R14;

		resume:
		  // return is not an option
			jmp XombThread._enterThreadScheduler;
		}
	}

private:
	// if the interrupt is owned locally, this is the registered handler
	void function()[256] handlers;

	/*
		if the interrupt has been (or is being) reserved by a child
		process, this is its root page table's virtual address
	*/
	ulong[256] childaddrs;

	/*
		just used as a preallocated place to stash the thread to be
		resumed when we hear back about an interrupt resevation
	*/
	ulong[256] savespot;

	/*
		reservation indicator fro synchronization purposes
		0 = free
		1 = reservation requested
		2 = reservation acknowledged
	*/
	ubyte[256] reservations;

	// XXX: yes these are opaque, thats the point.  the inline asm should be rich enough to avoid this?
	ulong* a_ptr = cast(ulong*)&handlers[0];
	ulong* b_ptr = cast(ulong*)&savespot[0];
	ulong* c_ptr = cast(ulong*)&childaddrs[0];
	ulong* reservation_ptr = cast(ulong*)&reservations[0];

	/* value that SHOULD be the result of
		 cast(ulong*)(root.getTable(255).entries.ptr) but that produces a
		 compiler error.  represents the begining of an array of the
		 physical addresses of child process address spaces
	*/
	const ulong base_addr = 0xFFFFFF7F_BFCFF000UL;

	/* the prior address is great for reading the page table entry, but
		 to refer to an address space the kernel expects it to be part of
		 a mapping, not the data pointed to. should be the same as
		 root.getTable(255).getTable(index_of_child).entries.ptr
	*/
	const ulong base_addr2 = 0xFFFFFF7F_9FE00000UL;
	}
