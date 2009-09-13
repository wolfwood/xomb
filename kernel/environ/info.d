/*
 * info.d
 *
 * This module describes an environment.
 *
 */

module kernel.environ.info;

import kernel.core.error;

import architecture;

struct Environment {
	void* start;
	void* virtualStart;

	void* entry;

	ulong length;

	PageTable pageTable;

	ErrorVal initialize() {
		// Create a page table for this environment
		pageTable.initialize();
		pageTable.alloc(virtualStart, length);

		pageTable.preamble(entry);

		return ErrorVal.Success;
	}

	ErrorVal preamble() {
		return ErrorVal.Success;
	}

	ErrorVal postamble() {
		return ErrorVal.Success;
	}

	void execute() {
		pageTable.execute();
	}
}

