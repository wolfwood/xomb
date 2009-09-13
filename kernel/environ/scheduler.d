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

struct Scheduler {
static:
public:

	ErrorVal initialize() {
		return ErrorVal.Success;
	}

	Environment* schedule() {
		kprintfln!("Scheduler.schedule()")();
		return (current = UniprocessScheduler.schedule());
	}

	Environment* newEnvironment() {
		kprintfln!("Scheduler.newEnvironment()")();
		return UniprocessScheduler.newEnvironment();
	}

	ErrorVal add(Environment* environ) {
		kprintfln!("Scheduler.add()")();
		return UniprocessScheduler.add(environ);
	}

	ErrorVal execute() {
		current.execute();

		// The previous function should NOT return
		// So if it does, fail
		return ErrorVal.Fail;
	}

private:

	Environment* current;
}
