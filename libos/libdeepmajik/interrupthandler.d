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
		// XXX request interrupt from init
		register_helper(id);

		// XXX somehow resume this thread when we hear back

		// do it
		handlers[id] = fun;

		return true;
	}

	void register_helper(ulong id){
		asm{
			naked;

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
		R11 - base address for mapped in child process root page tables
		R12 - address of the currently investigated child
		R13 - index of child
		R14 - mask for address field of Page Table Entry
		R15 - base of constructed address for return value
	*/

	void tmp_reservation_handler(){
		asm{
			naked;

			// XXX reply 'yes' to child

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

			//respond
			mov RDI, Syscall.StacklessYieldID;
			//mov RSI, 0;
			mov RDX, UpcallIndex.InterruptResponse;

			mov R9, 1;

			syscall;
		}
	}

	void tmp_response_handler(){
		asm{
			naked;

			// XXX assume response is for me, and resume thread

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


	void reservation_handler(){
		asm{
			naked;

			// XXX check if reservation is taken (or has an outstanding request)

			// XXX else remember which child requested for later routing

			// XXX and pass to parent
		}
	}

	void response_handler(){
		asm{
			naked;

			// XXX check if response is for me

			// XXX else pass to appropriate child
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
	void function()[256] handlers;
	ulong[256] savespot;

	// XXX: yes these are opaque, thats the point.  the inline asm should be rich enough to avoid this
	ulong* a_ptr = cast(ulong*)&handlers[0];
	ulong* b_ptr = cast(ulong*)&savespot[0];

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
