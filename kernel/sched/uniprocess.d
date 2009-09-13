/*
 * uniprocess.d
 *
 * This scheduler will only run one user app.
 *
 */

module sched.uniprocess;

import kernel.environ.info;

import kernel.core.error;

struct UniprocessScheduler {
static:

	// Do not do anything
	Environment* schedule() {
		return &environment;
	}

	// Set up the only environment
	Environment* newEnvironment() {
		if (numEnvironments == MAX_ENVIRONMENTS) {
			return null;
		}
		numEnvironments++;
		return &environment;
	}

	ErrorVal add(Environment* environ) {
		return ErrorVal.Success;
	}

protected:
	const uint MAX_ENVIRONMENTS = 1;

	Environment environment;
	uint numEnvironments;
}
