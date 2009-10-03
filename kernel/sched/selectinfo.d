module kernel.sched.selectinfo;

import kernel.config;

const char[] Implementation = Config.ReadOption!("SchedulerImplementation");

static if (Implementation == "UniprocessScheduler") {
	public import kernel.sched.uniprocess : SchedulerInfo;
}
else static if (Implementation == "RoundRobinScheduler") {
	public import kernel.sched.roundrobin : SchedulerInfo;
}
else {
	pragma(msg, "Scheduler Implementation Not Found: " ~ Implementation);
}
