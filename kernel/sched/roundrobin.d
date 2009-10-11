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
import kernel.core.kprintf;

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
			kprintfln!("woo")();
		Environment* next;
		if (current !is null) {
			current.state = Environment.State.Ready;
			next = current.info.next;
		}
		else {
			next = head;
		}

		assert(next !is null, "Nothing to schedule");
			kprintfln!("woo2")();
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
			head.info.next = head;
			head.info.prev = head;
			ret = &environments[0];
		}
		else {
			foreach(uint i, env; environments) {
				if (env.state == Environment.State.Inactive) {
					ret = &environments[i];
					ret.info.next = head;	
					ret.info.prev = head.info.prev;
					head.info.prev = ret;
					head = ret;
					break;
				}
			}
		}
		numEnvironments++;
		ret.state = Environment.State.Initializing;
		kprintfln!("ret: {}, {}")(ret, numEnvironments);
		return ret;
	}

	ErrorVal removeEnvironment(Environment* environment) {
		kprintfln!("removing: {}")(numEnvironments);
		if (numEnvironments == 1) {
			head = null;
			tail = null;
			kprintfln!("No More Environments")();
			for(;;) {}
		}
		else {
			environment.info.next.info.prev = environment.info.prev;
			environment.info.prev.info.next = environment.info.next;
		}
		environment.state = Environment.State.Inactive;
		numEnvironments--;
		return ErrorVal.Success;
	}

protected:
	const uint MAX_ENVIRONMENTS = 512;

	Environment[512] environments;
	uint numEnvironments;

	Environment* head;
	Environment* tail;
}
