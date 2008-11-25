// table.d -- Environment Table

module kernel.environment.table;

import kernel.arch.vmem;
import kernel.arch.context;	// context switch save, restore

import kernel.core.error;
import kernel.core.modules;

import kernel.dev.vga;

struct Environment
{
	vMem.PageTable pageTable;	// The page table

	uint id;					// environment id

	void* stack;				// stack
	void* stackPtr;				// current stack pointer

	void* registers;			// register stack
								// where the registers are saved (and other context information)
								// has a fairly complicated set up
			
								//  +0 - ptr to bottom (is at register stack)
								//  +8 - SS (INT)
								// +16 - RSP (INT)
								// +24 - RFLAGS (INT)
								// +32 - CS (INT)
								// +40 - RIP (INT)
								// +48 - ERROR CODE (INT)
								// +56 - INT NUMBER (INT)
								// +64 - GENERAL REGISTERS (contextSwitchSave!())

	//void* heap;				// heap (probably want information about the individual pages)

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

		// map in context space (1:1 mapping)
		// map(physaddr, length)
		pageTable.map(cast(ubyte*)GRUBModules.getStart(modNumber), GRUBModules.getLength(modNumber));

		entry = GRUBModules.getEntry(modNumber);		
	}

	void* tmpPtr;
	// code executed as this environment gets set to run
	ErrorVal preamble()
	{
		// use page table
		pageTable.use();

		// use stack
	//	mixin(contextStackRestore!("stackPtr"));

		////void* tmpPtr;
		//mixin(contextStackSave!("tmpPtr"));

		kprintfln!("Stack switched: {x}")(tmpPtr);

		return ErrorVal.Success;
	}

	// code executed as this environment gets switched
	ErrorVal postamble()
	{
		return ErrorVal.Success;
	}

	ErrorVal initPageTable()
	{
		pageTable.init();
		
		return ErrorVal.Success;		
	}

	ErrorVal initStack()
	{
		// allocate 8K environment stack
		pageTable.mapStack(stackPtr);
		stack = stackPtr - (2 * vMem.PAGE_SIZE);

		// allocate 4K register stack
		pageTable.mapRegisterStack(registers);	

		// now, context save (for sanity of scheduling)
		//mixin(contextSwitchSave!());	
	
		return ErrorVal.Success;
	}

	// deconstruct the environment
	void uninit()
	{
		kprintfln!("uninit page")();
		// free the pages we used
		pageTable.uninit();

		kprintfln!("uninit stack")();
		// free stack
		vMem.freePage(stack);
		vMem.freePage(stack + vMem.PAGE_SIZE);
	}
}



struct EnvironmentTable
{

static: 

	Environment** addr;	// address of the environment table
	int count;	// number of environments in the table

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

		// double the size (allow 1024 entries)
		vMem.getKernelPage(pageAddr);

		return ErrorVal.Success;
	}	

	ErrorVal newEnvironment(out Environment* environment)
	{
		if (count== MAX_ENVIRONMENTS)
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
		//*environment = Environment.init;	

		// set id
		environment.id = i;

		// now we can set up common stuff
		environment.initPageTable();	// create a user page table	

		kprintfln!("init stack")();
		environment.initStack();

		// up the length
		count++;

		kprintfln!("count: {}")(count);

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

	void removeEnvironment(uint environmentIndex)
	{
		if (environmentIndex >= MAX_ENVIRONMENTS || addr[environmentIndex] is null)
		{
			kprintfln!("Scheduler: removeEnvironment(): ERROR: invalid environment index")();
			return;
		}

		// decrement length
		count--;

		kprintfln!("count: {}")(count);

		// uninitialize internals of environment
		addr[environmentIndex].uninit();

		kprintfln!("Scheduler: removeEnvironment(): Environment Uninitialized")();
		// free page used by environment descriptor
		vMem.freePage(addr[environmentIndex]);

		kprintfln!("Scheduler: removeEnvironment(): Environment Page Freed")();
		// remove from table
		addr[environmentIndex] = null;
	}

}

