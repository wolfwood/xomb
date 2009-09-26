/*
 * roundrobin.d
 *
 * This scheduler allows more than one app, scheduled per CPU
 *   in a priority-less round-robin fashion.
 *
 */

module kernel.sched.roundrobin;

import kernel.environ.info;
import kernel.core.error;

// Linked List Structure
struct SchedulerInfo {
	Environment* next;
	Environment* prev;
}

struct RoundRobinScheduler {
static:

	ErrorVal initialize() {
		return ErrorVal.Success;
	}

	// Return next environment
	Environment* schedule(Environment* current) {
		if (current !is null) {
			current.state = Environment.State.Ready;
		}
		Environment* next = current.info.next;
		while(next.state != Environment.State.Ready) {
			next = next.info.next;
		}

		next.state = Environment.State.Running;
		return next;
	}

	// Set up a new environment
	Environment* newEnvironment() {
		if (numEnvironments == MAX_ENVIRONMENTS) {
			return null;
		}

		Environment* ret = null;
		if (numEnvironments == 0) {
			head = &environments[0];
			tail = head;
			ret = &environments[0];
		}
		else {
			foreach(uint i, env; environments) {
				if (env.state == Environment.State.Inactive) {
					ret = &environments[i];
					ret.info.next = head;	
					ret.info.prev = head.prev;
					head.prev = ret;
					head = ret;
					break;
				}
			}
		}
		numEnvironments++;
		ret.state = Environment.State.Initializing;
		return ret;
	}

	ErrorVal removeEnvironment(Environment* environment) {
		environment.state = Environment.State.Inactive;
		if (numEnvironments == 1) {
			head = null;
			tail = null;
		}
		else {
			environment.next.prev = environment.prev;
			environment.prev.next = environment.next;
		}
	}

protected:
	const uint MAX_ENVIRONMENTS = 512;

	Environment[512] environments;
	uint numEnvironments;

	Environment* head;
	Environment* tail;
}
