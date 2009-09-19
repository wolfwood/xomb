/*
 * scheduler.d
 *
 * Common interface to a scheduler.
 *
 */

module environ.scheduler;

import kernel.core.error;

import kernel.environ.info;

import kernel.sched.uniprocess;

import kernel.core.kprintf;
import kernel.core.log;

struct Scheduler {
static:
public:

	ErrorVal initialize() {
		return ErrorVal.Success;
	}

	Environment* schedule() {
		printToLog("Scheduler: schedule()");
		printSuccess(); 
		return (_current = UniprocessScheduler.schedule());
	}

	Environment* newEnvironment() {
		printToLog("Scheduler: newEnvironment()");
		printSuccess(); 
		return UniprocessScheduler.newEnvironment();
	}

	ErrorVal add(Environment* environ) {
		return printToLog("Scheduler: add()",UniprocessScheduler.add(environ));
	}

	ErrorVal execute() {
		_current.execute();

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
