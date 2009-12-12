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

import architecture.mutex;

// Linked List Structure
struct SchedulerInfo {
	Environment* next;
	Environment* prev;
	uint id;
}

class RoundRobinScheduler {
static:

	ErrorVal initialize() {
		return ErrorVal.Success;
	}

	// Return next environment
	synchronized Environment* schedule(Environment* current) {
		Environment* next;
		if (current !is null) {
			if (current.state == Environment.State.Running) {
				current.state = Environment.State.Ready;
			}
			next = current.info.next;
		}
		else {
			kprintfln!("current state is null")();
			next = head;
		}

		assert(next !is null, "Nothing to schedule");
		while(next.state != Environment.State.Ready) {
			next = next.info.next;
		}

		kprintfln!("Scheduling {}")(next.info.id);

		next.state = Environment.State.Running;
		return next;
	}

	// Set up a new environment
	synchronized Environment* newEnvironment() {
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
			ret.info.id = 0;
		}
		else {
			foreach(uint i, env; environments) {
				if (env.state == Environment.State.Inactive) {
					ret = &environments[i];
					ret.info.id = i;
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
		//kprintfln!("ret: {}, {}")(ret, numEnvironments);
		return ret;
	}

	synchronized ErrorVal removeEnvironment(Environment* environment) {
		//kprintfln!("removing: {}")(numEnvironments);
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
