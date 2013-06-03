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
	// NB: RSI is the second argument normally, but this function thinks its the first
	void interrupt( ActivationFrame* activation, ulong upcallId){
		char[8] temp;

		Console.putString(itoa(temp, 'd', activation.act.stash.intNumber));
		Console.putString("<!>");

		// if its a registered interrupt, we can grab it, otherwise give to init
		if(handlers[activation.act.stash.intNumber] !is null){
			handlers[activation.act.stash.intNumber]();
		}
		// else {pass to parent}


		// return is not an option
		XombThread._enterThreadScheduler();
	}

private:
	void function()[256] handlers;
}
