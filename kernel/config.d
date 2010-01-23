module kernel.config;

// Debugging options

// Setting DEBUG_ALL to true will cause *ALL* debug
// flags to turn on.  If you only want to see some
// debug messages, turn DEBUG_ALL off, and only
// turn on the debug messages you wish to see.
const auto DEBUG_ALL = false;

// Individual debug options
const auto DEBUG_PAGING = false;
const auto DEBUG_PAGEFAULTS = false;
const auto DEBUG_PMEM = false;
const auto DEBUG_INTERRUPTS = false;
const auto DEBUG_MPTABLE = false;
const auto DEBUG_LAPIC = false;
const auto DEBUG_IOAPIC = false;
const auto DEBUG_APENTRY = false;
const auto DEBUG_KBD = false;
const auto DEBUG_SCHEDULER = false;

const auto SMP_MAX_CORES = 4;

struct Config {
static:

	// Scheduler Implementation
	// Options:
	//    UniprocessScheduler
	//    RoundRobinScheduler
//	const char[] SchedulerImplementation = "UniprocessScheduler";
	const char[] SchedulerImplementation = "RoundRobinScheduler";

	// ReadOption!("SchedulerImplementation")
	// Returns the value of a configuration option
	template ReadOption(char[] Option) {
		mixin("const char[] ReadOption = (Config." ~ Option ~ ".stringof)[1..$-1];");
	}

	// For implementing config options as aliases
	template Alias(char[] Option) {
		const char[] Alias = "alias " ~ ReadOption!(Option) ~ " " ~ Option ~ ";";
	}
}

public import HeapImplementation = kernel.mem.bitmap;
public import PageAllocatorImplementation = kernel.mem.bitmap;
