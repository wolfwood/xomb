module libos.libdeepmajik.interrupthandler;

import libos.libdeepmajik.threadscheduler;

import libos.console;
import user.activation;
import util;


struct Handler{
	static:
	bool register( ulong id, void function() fun){
		// XXX request interrupt from init

		// XXX somehow resume this thread when we hear back

		// do it
		handlers[id] = fun;

		return true;
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
	ulong* a_ptr = cast(ulong*)&handlers[0];
}
