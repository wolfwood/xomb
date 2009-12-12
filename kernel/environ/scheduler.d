/*
 * scheduler.d
 *
 * Common interface to a scheduler.
 *
 */

module kernel.environ.scheduler;

import kernel.environ.info;

import kernel.core.error;
import kernel.core.kprintf;
import kernel.core.log;

import kernel.sched.roundrobin;
import kernel.config;

import architecture.cpu;
import architecture.perfmon;
import architecture.timing;

alias RoundRobinScheduler SchedulerImplementation;

struct Scheduler {
static:
public:

	ErrorVal initialize() {
		Log.print("Scheduler: " ~ Config.ReadOption!("SchedulerImplementation") ~ ".initialize()");
		return Log.result(SchedulerImplementation.initialize());
	}

	Environment* schedule() {
		Log.print("Scheduler: schedule()");
		current = SchedulerImplementation.schedule(current);

		if (current is null) {
			Log.result(ErrorVal.Fail);
			return null;
		}

		Log.result(ErrorVal.Success);
		return current;
	}

	Environment* newEnvironment() {
		Log.print("Scheduler: newEnvironment()");
		Environment* newEnv = SchedulerImplementation.newEnvironment();
		if (newEnv is null) {
			Log.result(ErrorVal.Fail);
		}
		else {
			Log.result(ErrorVal.Success);
		}
		return newEnv;
	}

	ErrorVal removeEnvironment() {
		Log.print("Scheduler: removeEnvironment()");
		ulong _perfCounterEnd = PerfMon.pollEvent(0);
		_perfCounter = _perfCounterEnd - _perfCounter;
		Time curtime;
		Timing.currentTime(curtime);
		kprintfln!("at {}:{}:{}")(curtime.hours, curtime.minutes, curtime.seconds);
		kprintfln!("Performance Monitor Result: {}")(_perfCounter);
		Environment* cur = current;
		cur.state = Environment.State.Uninitializing;
		cur.uninitialize();
		Log.result(ErrorVal.Success);

		current = null;

		return SchedulerImplementation.removeEnvironment(cur);
	}

	ErrorVal execute() {
		_perfCounter = PerfMon.pollEvent(0);
		Timing.currentTime(_last);
		kprintfln!("at {}:{}:{}")(_last.hours, _last.minutes, _last.seconds);
		kprintfln!("execute {}")(current.info.id);
		if (current !is null) {
			current.execute();
		}

		// The previous function should NOT return
		// So if it does, fail
		return ErrorVal.Fail;
	}

	Environment* current() {
//		kprintfln!("{} = _current[{}]")(_current[Cpu.identifier].info.id, Cpu.identifier);
		return _current[Cpu.identifier];
	}

	void current(Environment* cur) {
//		kprintfln!("_current[{}] = {}")(Cpu.identifier, _current[Cpu.identifier].info.id);
		_current[Cpu.identifier] = cur;
	}

	void apSchedule(){
		while(_bspInitComplete == false){}
		
		schedule();
		execute();
	}

	void kmainComplete(){
		_bspInitComplete = true;
	}
private:

	Environment* _current[SMP_MAX_CORES];

	bool _bspInitComplete;
	ulong _perfCounter;

	Time _last;
}
