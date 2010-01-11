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

import kernel.core.util;
import kernel.core.log;

import architecture.vm;

extern(C) void* memcpy(void*, void*, size_t); 

struct Loader {
static:

	// This function will load all modules.
	ErrorVal loadModules() {
		for(uint i = 0; i < System.numModules; i++) {
			// Map in module

			System.moduleInfo[i].virtualStart = cast(ubyte*)VirtualMemory.mapRegion(System.moduleInfo[i].start, System.moduleInfo[i].length);
			Log.print("Loader: loadFromModule()");
			Log.result(loadFromModule(i));
		}	
		return ErrorVal.Success;
	}

	// This function will load an executable from a module, if it can.
	ErrorVal loadFromModule(uint index) {

		// check bounds
		if (index >= System.moduleInfo.length) {
			return ErrorVal.Fail;
		}

		if (index >= System.numModules) {
			return ErrorVal.Fail;
		}

		// Check the module for being a compatible executable
		ubyte* moduleAddr = System.moduleInfo[index].virtualStart;
		if (Elf.isValid(moduleAddr)) {
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
				environ.length = System.moduleInfo[index].length - Elf.getoffset(moduleAddr);

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
		}

		return ErrorVal.Success;
	}	
}
