/*
 * multicore-uniprocess.d
 *
 * This scheduler allows more than one app, with one or more CPUs
 *   in a priority-less round-robin fashion.
 *
 */

module kernel.sched.multicore_uniprocess;

import kernel.environ.info;
import kernel.environ.scheduler;

import architecture.multiprocessor;
import architecture.mutex;
import architecture.cpu;

import kernel.core.error;
import kernel.core.kprintf;

// Linked List Structure
struct SchedulerInfo {
	Environment* next;
	Environment* prev;
}

struct MulticoreUniprocessScheduler {
static:

  ErrorVal initialize() {
   	assert(Multiprocessor.cpuCount >= idlers.length);

		// lock stuff so APs idle til we do and ulock and let them go hog wild
		foreach(perIdler il ; idlers){
			il.lock.lock();
		}

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

	void idleOrExecute(){
		auto id = Cpu.identifier();

		while(true){
			idlers[id].lock.lock();

			Environment* temp = Scheduler.current();
			
			if(temp.numHwThreads <= id){
				continue;
			}

			
			for(int i = 0; i < id; i++){
				temp = temp.next;
			}

			temp.execute();
		}
	}

protected:
	const uint MAX_ENVIRONMENTS = 512;

	Environment[512] environments;
	uint numEnvironments;

	Environment* head;
	Environment* tail;

	perIdler[8] idlers;

	struct perIdler{
		Mutex lock;
		
	}
}
