module kernel.sched.select;

import kernel.config;

const char[] Implementation = Config.ReadOption!("SchedulerImplementation");

static if (Implementation == "UniprocessScheduler") {
	public import kernel.sched.uniprocess : UniprocessScheduler, SchedulerInfo;
	alias UniprocessScheduler SchedulerImplementation;
}
else static if (Implementation == "RoundRobinScheduler") {
	public import kernel.sched.roundrobin : UniprocessScheduler, SchedulerInfo;
	alias RoundRobinScheduler SchedulerImplementation;
}
else {
	pragma(msg, "Scheduler Implementation Not Found: " ~ Implementation);
}
