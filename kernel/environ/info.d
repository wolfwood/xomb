/*
 * info.d
 *
 * This module describes an environment.
 *
 */

module kernel.environ.info;

import kernel.core.error;

import kernel.system.segment;

import architecture;

struct Environment {
	void* start;
	void* virtualStart;

	void* entry;

	ulong length;

	Context context;

	ErrorVal initialize() {
		// Create a page table for this environment
		context.initialize();

		context.preamble(entry);

		return ErrorVal.Success;
	}

	ErrorVal allocSegment(ref Segment s) {
		return context.allocSegment(s);
	}

	ErrorVal preamble() {
		return ErrorVal.Success;
	}

	ErrorVal postamble() {
		return ErrorVal.Success;
	}

	void execute() {
		context.execute();
	}
}

