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

import kernel.sched.select;
import kernel.config;

struct Scheduler {
static:
public:

	ErrorVal initialize() {
		return printToLog("Scheduler: " ~ Config.ReadOption!("SchedulerImplementation") ~ ".initialize()", SchedulerImplementation.initialize());
	}

	Environment* schedule() {
		printToLog("Scheduler: schedule()");
		_current = SchedulerImplementation.schedule(_current);

		if (_current is null) {
			printFail();
			return null;
		}

		printSuccess();
		return _current;
	}

	Environment* newEnvironment() {
		printToLog("Scheduler: newEnvironment()");
		printSuccess(); 
		Environment* newEnv = SchedulerImplementation.newEnvironment();
		return newEnv;
	}

	ErrorVal removeEnvironment() {
		Environment* cur = current;
		cur.state = Environment.State.Uninitializing;
		cur.uninitialize();
		return SchedulerImplementation.removeEnvironment(cur);
	}

	ErrorVal execute() {
		if (_current !is null) {
			_current.execute();
		}

		// The previous function should NOT return
		// So if it does, fail
		return ErrorVal.Fail;
	}

	Environment* current() {
		return _current;
	}

private:

	Environment* _current;
}
