// timer.d -- Used to get a high performance timer... right now just uses HPET

module kernel.arch.x86_64.timer;

import kernel.arch.x86_64.hpet;
import kernel.arch.x86_64.idt;
import kernel.core.error;

struct Timer
{

static:

	// initializes the timer
	ErrorVal init()
	{
		// use HPET
		return HPET.init();
	}

	// initializes the first available timer, one-shot
	int initTimer(ulong picoseconds, InterruptHandler timerProc)
	{
		HPET.initTimer(0, picoseconds, timerProc);

		return 0;
	}

	// reset the given timer
	void resetTimer(uint idx, ulong picoseconds)
	{
		HPET.resetTimer(idx, picoseconds);
	}
}
