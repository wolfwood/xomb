module kernel.arch.select;

// Import the architecture interfaces
// This is found in the kernel/arch/ARCHLABEL/imports/ folder
// This will be copied to the dsss_imports directory
import archimport;


// Common imports
import kernel.core.error;


// The following implement the architecture independent interfaces


// -- Architecture -- //

struct Architecture
{
static:
public:

	ErrorVal initialize()
	{
		return archInitialize();
	}
}

// -- Cpu -- //

struct Cpu
{
static:
public:

	ErrorVal initialize()
	{
		return cpuInitialize();
	}

	// The interface to the CpuInfo structure
	CpuInfo* info;

private:

	// This struct defines common attributes about the
	// current CPU being executed
	struct CpuInfo
	{
	}
}

// -- Multiprocessor -- //

struct Multiprocessor
{
static:
public:

	ErrorVal initialize()
	{
		return mpInitialize();
	}

private:
}
