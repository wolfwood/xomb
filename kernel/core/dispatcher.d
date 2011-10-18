module core.dispatcher;

import architecture.timing;
import architecture.cpu;

import kernel.arch.x86_64.core.idt;
import kernel.arch.x86_64.core.lapic;

import kernel.core.kprintf;
import kernel.core.error;

import user.activation;
import user.types;

struct Dispatcher{
	static:

	ErrorVal initialize() {
		Timing.startTimer(&hpetHandler, 100);

		return ErrorVal.Success;
	}


private:

	void hpetHandler(InterruptStack* s){
		kprintfln!(">!<\n")();
		activation[] activations = (cast(activation*)((1024*1024*1024) - 4096))[0..numberOfActivations];

		// find a free activation
		uint idx = findFreeActivation();

		// stash the state that will be overwritten to return control to the thread scheduler
		/*
			activations[idx].rip = s.rip;
			activations[idx].rdi = s.rdi;
			activations[idx].rsi = s.rsi;
		*/
		activations[idx].stash = *s;


		// communicate the activation to userspace
		//		Cpu.writeMSR(FSBASE_MSR, cast(ulong)&activations[idx]);

		// acknowledge the interrupt
		LocalAPIC.EOI();


		// Control Return approaches
		//   a) combine well-known entry with interrupt return, pass most state in registers
		//   b) memcopy all CPU state to activation from
		//   c) return to init instead
		//
		// Optimizations:
		//   a) save fewer registers, hand-code fast path
		//   b) read only user mapping of activation, directly use activation as interrupt stack
		//   c) vector memcpy, write an entire cacheline to avoid a read?

		Cpu.enterUserspace(4,cast(PhysicalAddress)&(activations[idx].stash));
	}
}