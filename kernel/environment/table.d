// table.d -- Environment Table

module kernel.environment.table;

import kernel.arch.vmem;
import kernel.arch.context;	// context switch save, restore

import kernel.arch.syscall;

import kernel.core.error;
import kernel.core.modules;
import kernel.core.util;

import kernel.dev.keyboard;
import kernel.dev.vga;

// XXX: frame pointer hack
void nullFunc()
{
  asm { naked; "retq"; }
}

// Environment Entry
//
// id			- index into table, unique for environment
// size			- size of data
// state		- the current state of execution
// entry		- entry point into the environment
//				- maybe, it could have multiple entry points
// cpuCount		- number of cpus this environment needs
// content		- the data portion (lower half of memory)
//
// (per cpu sections)
//
// pageTables	- pointer to a list of pagetables

// REGISTER_STACK Layout
//
// x86
//
// has a fairly complicated set up
//
//  -0 - ptr to bottom (is at register stack)
//  -8 - SS (INT)
// -16 - RSP (INT)
// -24 - RFLAGS (INT)
// -32 - CS (INT)
// -40 - RIP (INT)
// -48 - ERROR CODE (INT)
// -56 - INT NUMBER (INT)
// -64 - GENERAL REGISTERS (contextSwitchSave!())
//

struct Environment
{

  enum State
  {
    Ready,
    Running,
    Blocked,
  }

  enum Devices
  {
    Keyboard = 1,		// Keyboard buffer
    Console = 2,		// Console frame buffer
  }


  uint cpuCount;				// number of cpus this environment needs
  uint id;					// environment id
  void* content;				// environment data, code
  ulong size;					// environment size
  State state;				// current state of execution

  // the Devices enum are the flags for the following variable
  // if the bit is set, the environment controls the resource
  // if the process is unloaded, the device heaps will be
  // destroyed, therefore, the environment needs to alert
  // the resource as well.
  long deviceUsage;

  void* entry;				// entry into the execution space

  // per cpu

  // should be physical addresses (eventually)

  vMem.PageTable pageTable;	// environment page table

  //void* heap;				// heap (probably want information about the individual pages)
}

// will load the environment (using a loader)
void load(Environment* environ)
{
  // TODO: load an executable file of our design (multiple cpus and entry points?)
  environ.content = null;
  environ.size = 0;
}

// will load the environment (using grub module)
void loadGRUBModule(Environment* environ, uint modNumber)
{
  // code lives at where GRUB tells us it lives
  // contextSpace...

  // map in context space (1:1 mapping)
  // map(physaddr, length)

  // cpus are set to 1
  environ.cpuCount = 1;

  environ.pageTable.map(cast(ubyte*)GRUBModules.getStart(modNumber), GRUBModules.getLength(modNumber), cast(void*)0x400000);

  environ.entry = 0x400000 + GRUBModules.getEntry(modNumber);

  // look at BSS
  void* bss;
  uint bssLength;

  if (GRUBModules.fillBSSInfo(modNumber, bss, bssLength))
  {
    //kprintfln!("Module {} bss: {x} for {} bytes")(modNumber, bss, bssLength);

    // zero the section out
    ubyte* bssSection = cast(ubyte*)bss;

    bssSection[0 .. bssLength] = 0;
  }
  else
  {
    //kprintfln!("Module {} no BSS!")(modNumber);
  }
}

// code executed as this environment gets set to run
ErrorVal preamble(Environment* environ)
{
  // use page table
  environ.pageTable.use(0);

  // switch stack
  if (environ.state == Environment.State.Blocked) {
    environ.state = Environment.State.Running;
  }

  return ErrorVal.Success;
}

// Code for execute
ErrorVal execute(Environment* environ)
{
  // first execution?
  if (environ.state == Environment.State.Ready)
  {
    // has not been executed yet
    environ.state = Environment.State.Running;

    // create a mock stack
    //mixin(contextSwitchPrepare!("environ.entry"));
    prepare(environ.entry);

    return ErrorVal.Success;
  }

  // Call the preamble code first, then execute.
  return ErrorVal.Success;
}

void prepare(void* entry)
{
  mixin(contextSwitchPrepare!("environ.entry"));
}

// code executed as this environment gets switched
ErrorVal postamble(Environment* environ)
{
  nullFunc();

  environ.state = Environment.State.Blocked;

  return ErrorVal.Success;
}

ErrorVal initPageTable(Environment* environ)
{
  environ.pageTable.init(environ.cpuCount);

  return ErrorVal.Success;
}

ErrorVal initStack(Environment* environ)
{
  // allocate 8K environment stack
  void* stack;
  void* registers;
  environ.pageTable.mapStack(stack);
  stack = stack - (vMem.ENVIRONMENT_STACK_PAGES * vMem.PAGE_SIZE);

  // allocate 4K register stack
  environ.pageTable.mapRegisterStack(registers);

  // now, context save (for sanity of scheduling)
  //mixin(contextSwitchSave!());
  return ErrorVal.Success;
}

// deconstruct the environment
void uninit(Environment* environ)
{
  if (environ.deviceUsage & Environment.Devices.Keyboard)
  {
    // keyboard has been inited here
    // uninit the keyboard
    Keyboard.unsetBuffer();
  }

  //kprintfln!("uninit page")();
  // free the pages we used
  environ.pageTable.uninit();

  //kprintfln!("uninit stack")();
  // XXX: free stack
  //vMem.freePage(stack);
  //vMem.freePage(stack + vMem.PAGE_SIZE);
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

    if (vMem.getKernelPage(pageAddr) == ErrorVal.Fail)
    {
      return ErrorVal.Fail;
    }

    return ErrorVal.Success;
  }

  ErrorVal cloneEnvironment(out Environment* environment, Environment* original)
  {
    if (count == MAX_ENVIRONMENTS)
    {
      return ErrorVal.Fail;
    }
kprintfln!("cloneEnvironment: Looking for slot.")();
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
kprintfln!("cloneEnvironment: Found Slot. {}")(i);
    void* envEntry;
kprintfln!("cloneEnvironment: Allocating Environment Entry.")();
    if (vMem.getKernelPage(envEntry) == ErrorVal.Fail)
    {
      return ErrorVal.Fail;
    }
kprintfln!("cloneEnvironment: Entry Allocated.")();
    // set the environment descriptor address into the environment table
    addr[i] = cast(Environment*)envEntry;
kprintfln!("cloneEnvironment: A")();
    environment = addr[i];
kprintfln!("B")();
    *environment = Environment.init;

	environment.cpuCount = original.cpuCount;
	environment.pageTable.init(environment.cpuCount);

	environment.size = original.size;
kprintfln!("C")();


    original.pageTable.copyTo(&(environment.pageTable));
kprintfln!("D")();
    // should zero out the initial sections
    //*environment = Environment.init;

    // set id
    environment.id = i;
    original.deviceUsage = 0;

kprintfln!("cloneEnvironment: Setup Complete.")();

    // set it to ready (not running)
    environment.state = Environment.State.Blocked;

    // up the length
    count++;

    //kprintfln!("count: {}")(count);

kprintfln!("cloneEnvironment: Done.")();

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
    environment.deviceUsage = 0;

    // set it to ready (not running)
    environment.state = Environment.State.Ready;

    // now we can set up common stuff
    initPageTable(environment);	// create a user page table

    //kprintfln!("init stack")();
    initStack(environment);

    // up the length
    count++;

    //kprintfln!("count: {}")(count);

    return ErrorVal.Success;
  }

  // returns the environment descriptor at the current index of the environment table
  Environment* getEnvironment(uint environmentIndex)
  {
    if (environmentIndex < MAX_ENVIRONMENTS)
    {
      return addr[environmentIndex];
    }

    nullFunc();

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

    //kprintfln!("count: {}")(count);

    // uninitialize internals of environment
    uninit(addr[environmentIndex]);

    kprintfln!("Scheduler: removeEnvironment(): Environment Uninitialized")();
    // free page used by environment descriptor
    vMem.freePage(addr[environmentIndex]);

    kprintfln!("Scheduler: removeEnvironment(): Environment Page Freed")();
    // remove from table
    addr[environmentIndex] = null;
  }



}

