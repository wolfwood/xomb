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
		current = SchedulerImplementation.schedule(current);

		if (current is null) {
			return null;
		}

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
		Environment* cur = current;
		cur.state = Environment.State.Uninitializing;
		cur.uninitialize();

		current = null;

		return SchedulerImplementation.removeEnvironment(cur);
	}

	ErrorVal execute() {
		if (current !is null) {
			current.execute();
		}

		// The previous function should NOT return
		// So if it does, fail
		kprintfln!("FAIL")();
		return ErrorVal.Fail;
	}

	Environment* current() {
		return _current[Cpu.identifier];
	}

	void current(Environment* cur) {
		_current[Cpu.identifier] = cur;
	}

	void idleLoop(){
		while(_bspInitComplete == false){}
		
		while(schedule() == null){}

		execute();
	}

	void kmainComplete(){
		_bspInitComplete = true;
	}
private:

	Environment* _current[SMP_MAX_CORES];

	bool _bspInitComplete;
}
