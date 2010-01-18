
module kernel.filesystem.ramfs;

import kernel.system.info;
import kernel.core.error;
import kernel.mem.heap;

import kernel.core.kprintf;

import kernel.environ.info;
import kernel.environ.scheduler;

import architecture.vm;

import kernel.mem.giballocator;
import kernel.mem.gib;

import user.ramfs;

class RamFS {
static:
	ErrorVal initialize() {
		// Make root
		rootDir = GibAllocator.alloc(Access.Kernel | Access.Read | Access.Write);

		return ErrorVal.Fail;
	}

	void mkdir(Gib curDir) {
		// Check curDir permissions
		// ...

		// Create new directory Gib
		Gib newDir = GibAllocator.alloc(Access.Kernel | Access.Read | Access.Write);

		// form this new directory
		// ...

		// link curDir to this new directory
		// ...

		// close kernel Gib
		// ...

	}

	ErrorVal destroy() {
		return ErrorVal.Fail;
	}

	ErrorVal create() {
		// Create a new Gib
		// ...

		return ErrorVal.Fail;
	}

	ErrorVal open() {
		return ErrorVal.Fail;
	}

	ErrorVal close() {
		return ErrorVal.Fail;
	}

	ErrorVal link() {
		return ErrorVal.Fail;
	}

private:
	Gib rootDir;
}
