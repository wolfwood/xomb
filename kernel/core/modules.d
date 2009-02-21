// GRUB module information

module kernel.core.modules;

import kernel.core.elf;
import kernel.core.multiboot;
import kernel.arch.vmem;

import kernel.dev.vga;

struct GRUBModules
{

static:
	module_t* mods;	// The modules array (given by GRUB multiboot)
	uint length;	// Number of modules

	void init(multiboot_info_t* mbi)
	{
		mods = cast(module_t*)(mbi.mods_addr + vMem.VM_BASE_ADDR);
		length = mbi.mods_count;
	}

	void* getStart(uint modNumber)
	{
		if (modNumber >= length) { return null; }

		module_t* mod = mods + modNumber;

		return cast(void*)mod.mod_start;
	}

	ulong getLength(uint modNumber)
	{
		if (modNumber >= length) { return 0; }

		module_t* mod = mods + modNumber;

		return (mod.mod_end - mod.mod_start);
	}

	bool fillBSSInfo(uint modNumber, out void* bssAddress, out uint len)
	{
		if (modNumber >= length) { return 0; }

		module_t* mod = mods + modNumber;

		void* moduleAddress = cast(void*)mod.mod_start;
		moduleAddress += vMem.VM_BASE_ADDR;

		bool ret = ELF.fillBSSInfo(moduleAddress, bssAddress, len);

		bssAddress = moduleAddress + cast(ulong)(bssAddress);

		return ret;
	}

	void* getEntry(uint modNumber)
	{
		if (modNumber >= length) { return null; }

		//kprintfln!("mods: {x}")(mods);
		module_t* mod = mods + modNumber;

		//kprintfln!("mod: {x} modStart: {x}")(mod, mod.mod_start);

		void* moduleAddress = cast(void*)mod.mod_start;
		moduleAddress += vMem.VM_BASE_ADDR;

		return ELF.getEntry(moduleAddress);
	}
}
