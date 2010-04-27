/*
 * loader.d
 *
 * This module can load an executable.
 *
 */

module kernel.system.loader;

import kernel.system.elf;
import kernel.system.info;
import kernel.system.segment;

import kernel.environ.info;
import kernel.environ.scheduler;

import kernel.core.error;
import kernel.core.kprintf;

import kernel.mem.heap;
import kernel.mem.gib;
import kernel.mem.giballocator;

import kernel.core.util;
import kernel.core.log;

import kernel.filesystem.ramfs;

import architecture.vm;

struct Loader {
static:

	// This function will load all modules.
	ErrorVal loadModules() {
		for(uint i = 0; i < System.numModules; i++) {

			// Put module on file system

			kprintfln!("Creating {}")(System.moduleInfo[i].name);
			// Create the file
			Gib newGib = RamFS.create(System.moduleInfo[i].name, 
				Access.Kernel | Access.Read | Access.Write);

			// map the module into this file
			newGib.length(System.moduleInfo[i].length);
			newGib.map(System.moduleInfo[i].start, System.moduleInfo[i].length);

			newGib.close();

			kprintfln!("Loading {}")(System.moduleInfo[i].name);
			Log.print("Loader: load()");
			Log.result(load(System.moduleInfo[i].name));
		}	
		return ErrorVal.Success;
	}

	// This function will load an executable from a module, if it can.
	ErrorVal load(char[] path) {

		// Check the module for being a compatible executable
		Gib modGib = RamFS.open(path, Access.Kernel | Access.Read);
		ubyte* moduleAddr = modGib.ptr;

		if (!Elf.isValid(moduleAddr)) {
			// Not an executable
			modGib.close();
			return ErrorVal.Fail;
		}

		// Add executable flag
		RamFS.chmod(path, Directory.Mode.ReadOnly | Directory.Mode.Executable); 

		void* entryAddress = Elf.getentry(moduleAddr);
		void* physAddress = Elf.getphysaddr(moduleAddr);
		void* virtAddress = Elf.getvirtaddr(moduleAddr);
		//kprintfln!("ELF Module : {}\n  Entry: {x} p: {x} v: {x}")(index, entryAddress, physAddress, virtAddress);

		Segment curSegment;

		uint numSegments = Elf.segmentCount(moduleAddr);

		// Create an environment through the scheduler
		Environment* environ = Scheduler.newEnvironment();

		if (environ is null) {
			kprintfln!("No more environments!")();
			return ErrorVal.Fail;
		}
		else {
			// Load executable
			environ.virtualStart = virtAddress;
			environ.length = modGib.length() - Elf.getoffset(moduleAddr);

			//kprintfln!("Initializing this environment")();
			//environ.start = System.moduleInfo[index].start;
			environ.start = physAddress;
			//environ.virtualStart = moduleAddr;

			environ.entry = entryAddress;

			//kprintfln!("Initialize this environment")();
			environ.initialize();
			//kprintfln!("Loading this environment")();

			for(uint i; i < numSegments; i++) {
				curSegment = Elf.segment(moduleAddr, i);
				environ.allocSegment(curSegment);

				// Copy segment
				memcpy(curSegment.virtAddress, moduleAddr + curSegment.offset, curSegment.length);
			}
		}
		
		modGib.close();

		return ErrorVal.Success;
	}	
}
