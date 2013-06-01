module libos.libdeepmajik.interrupthandler;

import libos.libdeepmajik.threadscheduler;

import libos.console;

struct Handler{

	// this function MUST not return
	void interrupt(ulong id){

		Console.putString("<!>\n");

		// return is not an option
		XombThread._enterThreadScheduler();
	}
}