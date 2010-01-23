/*
 * uniprocess.d
 *
 * This scheduler will only run one user app.
 *
 */

module kernel.sched.uniprocess;

import kernel.environ.info;

import kernel.core.error;
import kernel.core.kprintf;

struct SchedulerInfo {
}

struct UniprocessScheduler {
static:

	ErrorVal initialize() {
		return ErrorVal.Success;
	}

	// Do not do anything
	Environment* schedule(Environment* current) {
		if (current !is null) {
			current.state = Environment.State.Ready;
		}
		if (environment.state == Environment.State.Ready) {
			environment.state = Environment.State.Running;
			return &environment;
		}
		return null;
	}

	// Set up the only environment
	Environment* newEnvironment() {
		if (numEnvironments == MAX_ENVIRONMENTS || environment.state != Environment.State.Inactive) {
			return null;
		}
		numEnvironments++;
		environment.state = Environment.State.Initializing;
		return &environment;
	}

	// Remove environment
	ErrorVal removeEnvironment(Environment* environment) {
		if (environment == &this.environment) {
			numEnvironments = 0;
			environment.state = Environment.State.Inactive;
			kprintfln!("Uniprocess Scheduler, removed environment, no more.")();
			for(;;) {}
			return ErrorVal.Success;
		}
		return ErrorVal.Fail;
	}

protected:
	const uint MAX_ENVIRONMENTS = 1;

	Environment environment;
	uint numEnvironments;
}
