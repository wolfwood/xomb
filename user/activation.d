module user.activation;

import user.types;
import synch.atomic;

version(KERNEL){
	import kernel.core.kprintf;	// For printing the stack dump
}else{
	import libos.libdeepmajik.threadscheduler;
 }

struct InterruptStack {
	// Registers
	ulong r15, r14, r13, r12, r11, r10, r9, r8;
	ulong rbp, rdi, rsi, rdx, rcx, rbx, rax;

	// Data pushed by the isr
	ulong intNumber, errorCode;

	// Pushed by the processor
	ulong rip, cs, rflags, rsp, ss;

	// This function will dump the stack information to
	// the screen. Useful for debugging.
	version(KERNEL){
		void dump() {
			kprintfln!("Stack Dump:")();
			kprintfln!("r15:{x}|r14:{x}|r13:{x}|r12:{x}|r11:{x}")(r15,r14,r13,r12,r11);
			kprintfln!("r10:{x}| r9:{x}| r8:{x}|rbp:{x}|rdi:{x}")(r10,r9,r8,rbp,rdi);
			kprintfln!("rsi:{x}|rdx:{x}|rcx:{x}|rbx:{x}|rax:{x}")(rsi,rdx,rcx,rbx,rax);
			kprintfln!(" ss:{x}|rsp:{x}| cs:{x}")(ss,rsp,cs);
		}
	}
}

void _entry(){
	asm{
		naked;

		movq RSP, RSI;
		popq R15;
		popq R14;
		popq R13;
		popq R12;
		popq R11;
		popq R10;
		popq R9;
		popq R8;
		popq RBP;
		popq RDI;
		popq RSI;
		popq RDX;
		popq RCX;
		popq RBX;
		popq RAX;

		add RSP, 16;

		// XXX: race between this intruction and the next, interrupt may take and overwrite activation
		mov [RSP + 0x28], 0;

		iretq;
	}
}

/* Chicken and egg problem: restore saved context
 *
 *  - can't restore RIP with an indirect move, as all registers will be occupied
 *  - can't pop RIP from stack because we can't trust their stack is pristine
 *  - can't use RIP-relative addressing to restore RSP as RIP varies
 *  - can't use RIP-relative addressing to restore RIP because acitvation location varies
 *
 */


/* chicken and egg solutions:
 *  a) use FS relative addressing to restore rsp and rip
 *  b) diable redzone and use stack
 *  c) call gate
 *
 */

struct Activation{
	InterruptStack stash;

	bool valid;
}

struct ActivationFrame {
	Activation act;

	version(KERNEL){
		ubyte stack[fourKB - Activation.sizeof];
	}else{
		ubyte stack[fourKB - Activation.sizeof -  XombThread.sizeof];
		XombThread t;
	}
}

const uint numberOfActivations = twoMB / ActivationFrame.sizeof;

uint findFreeActivation(){
	ActivationFrame[] activations = (cast(ActivationFrame*)((1024*1024*1024) - twoMB))[0..numberOfActivations];

	while(1){
		for(int i = 0; i < numberOfActivations; i++){
			if(!activations[i].act.valid){
				activations[i].act.valid = true;
				//if(Atomic.compareExchange(activations[i].valid,false, true)){
				return i;
				//}
			}
		}
	}
}
