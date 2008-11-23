// table.d -- Environment Table

module kernel.environment.table;

import kernel.arch.select;

import kernel.core.error;
import kernel.core.modules;

import kernel.dev.vga;

struct Environment
{
	vMem.PageTable pageTable;	// The page table

	void* stack;				// stack
	//void* heap;				// heap (probably want information about the pages)

	void* contextSpace;			// Where the code lives
	ulong contextSize;			// Size of the context space

	void* entry;				// Entry point, the address of the first instruction (in terms of the environment address space)

	// will load the environment (using a loader)
	void load()
	{
		// TODO: load an executable file
		contextSpace = null;
	}

	// will load the environment (using grub module)
	void loadGRUBModule(uint modNumber)
	{
		// code lives at where GRUB tells us it lives
		// contextSpace...

		// map in context space
		// vMem.mapUser...

		entry = GRUBModules.getEntry(modNumber);		
	}

	ErrorVal initPageTable()
	{
		void* pageAddr;
		if (vMem.getKernelPage(pageAddr) == ErrorVal.Fail)
		{
			return ErrorVal.Fail;
		}
	
		pageTable = cast(vMem.PageTable)(pageAddr);
		vMem.initUserPageTable(pageTable);
		
		return ErrorVal.Success;		
	}
}



struct EnvironmentTable
{

static: 

	Environment** addr;	// address of the environment table
	int length;	// number of environments in the table

	const int MAX_ENVIRONMENTS = 1024;

	ErrorVal init()
	{
		// create pages for the environment table in the kernel heap

		// create the first page... this will store 512 environment pointers
		// makes assumption that getKernelPage called twice will return consectutive pages
		void *pageAddr;
		if (vMem.getKernelPage(pageAddr) == ErrorVal.Fail)
		{
			return ErrorVal.Fail;
		}
		
		// retain the address
		addr = cast(Environment**)pageAddr;

		vMem.getKernelPage(pageAddr);

		return ErrorVal.Success;
	}	

	ErrorVal newEnvironment(out Environment* environment)
	{
		if (length == MAX_ENVIRONMENTS)
		{
			return ErrorVal.Fail;
		}
		
		// find empty table entry
		int i;
		for (i=0; i<MAX_ENVIRONMENTS; i++)
		{
			if (addr[i] is null)
			{
				break;
			}
		}
		if (i == MAX_ENVIRONMENTS)
		{
			// should not happen
			// means BUG in environment code
			// explanation: already checked if the length was at the maximum, length must be wrong
			kprintfln!("BUG: EnvironmentTable.newEnvironment")();
			return ErrorVal.Fail;
		}

		void* envEntry;
		if (vMem.getKernelPage(envEntry) == ErrorVal.Fail)
		{
			return ErrorVal.Fail;
		}

		// set the environment descriptor address into the environment table
		addr[i] = cast(Environment*)envEntry;

		environment = addr[i];

		// should zero out the initial sections
		*environment = Environment.init;	

		// now we can set up common stuff
		environment.initPageTable();	// create a user page table

		// up the length
		length++;

		return ErrorVal.Success;
	}

	// returns the environment descriptor at the current index of the environment table
	Environment* getEnvironment(uint environmentIndex)
	{
		if (environmentIndex < MAX_ENVIRONMENTS)
		{
			return addr[environmentIndex];
		}

		return null;
	}
}

