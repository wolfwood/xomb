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
import architecture.perfmon;
import architecture.cpu;

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
		schedLock.lock();

		Environment* next;
		if (current !is null) {
			if (current.state == Environment.State.Running) {
				current.state = Environment.State.Ready;
			}
			next = current.info.next;
		}
		else {
			next = head;
		}

		if (next is null) {
			//kprintfln!("Cannot find environment ready (list empty)")();
			schedLock.unlock();
			return null;
		}

		Environment* orig = next;
		while(next.state != Environment.State.Ready) {
			next = next.info.next;
			if (next is orig) {
				//kprintfln!("Cannot find environment ready (none in Ready state)")();
				schedLock.unlock();
				return null;
			}
		}

		next.state = Environment.State.Running;
		schedLock.unlock();
		//kprintfln!("Environment Scheduled {} {} {}")(Cpu.identifier, next, next.info.id);
		return next;
	}

	uint length() {
		return numEnvironments;
	}

	// Set up a new environment
	synchronized Environment* newEnvironment() {
		schedLock.lock();

		if (numEnvironments == MAX_ENVIRONMENTS) {
			schedLock.unlock();
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
					head.info.prev.info.next = ret;
					head.info.prev = ret;
					head = ret;
					break;
				}
			}
		}
		if (ret !is null) {
			numEnvironments++;
			ret.state = Environment.State.Initializing;
		}
		schedLock.unlock();
		return ret;
	}

	synchronized ErrorVal removeEnvironment(Environment* environment) {
		schedLock.lock();
//			kprintfln!("Removing... {}")(environment);

		if (numEnvironments == 0 || environment is null) {
			schedLock.unlock();
			for(;;){}
			return ErrorVal.Fail;
		}

		environment.state = Environment.State.Inactive;
		numEnvironments--;
		if (numEnvironments == 0) {
			head = null;
			tail = null;
			kprintfln!("No More Environments")();
			schedLock.unlock();
			return ErrorVal.Success;
		}
		else {
			environment.info.next.info.prev = environment.info.prev;
			environment.info.prev.info.next = environment.info.next;
			if (head is environment) {
				head = head.info.next;
			}
			if (tail is environment) {
				tail = tail.info.prev;
			}
		}
		schedLock.unlock();
		return ErrorVal.Success;
	}

protected:
	Mutex schedLock;

	const uint MAX_ENVIRONMENTS = 512;

	Environment[MAX_ENVIRONMENTS] environments;
	uint numEnvironments;

	Environment* head;
	Environment* tail;
}
