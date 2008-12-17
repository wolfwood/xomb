module kernel.environment.cputable; // -- keeps track of the availability of cpus that can be scheduled

// need allocator
import kernel.mem.pmem;

// need virtual memory information
import kernel.arch.vmem;

// need to lock this
import kernel.arch.locks;

// for print
import kernel.dev.vga;

struct CpuTable
{

static:

	uint numAvailable;	// number of cpus available

	// the table (bitmap)
	ubyte* cpuTable;

	// lock
	kmutex cpuTableMutex;

	// create the table
	void init()
	{
		//kprintfln!("cputable init")();
		cpuTable = (cast(ubyte*)pMem.requestPage()) + vMem.VM_BASE_ADDR;

		// set them all to zero as unavailable
		cpuTable[0..vMem.PAGE_SIZE] = 0;
	}

	// the cpu is now available
	void provide(uint cpuID)
	{
		ulong byteNum = cpuID / 8;
		ulong bitNum = cpuID % 8;

		ubyte mask = 1 << bitNum;

		cpuTableMutex.lock();
		cpuTable[byteNum] |= (mask);
		numAvailable++;
		cpuTableMutex.unlock();
	}

	// get a cpu that is available,
	// make it unavailable
	int consumeNext()
	{	
		if (numAvailable == 0) 
		{ 
			return -1; 
		}

		cpuTableMutex.lock();

		for (int i=0; i < vMem.PAGE_SIZE; i++) 
		{
			if (cpuTable[i] > 0x0)
			{
				ubyte check = cpuTable[i];

				uint cpuId = i * 8;
				ubyte mask = 1;
				while ((check & mask) > 0)
				{
					cpuId ++;
					mask <<= 1;
				}

				// make unavailable
				cpuTable[i] &= (~mask);

				cpuTableMutex.unlock();
				return cpuId;
			}
		}

		cpuTableMutex.unlock();

		// no available cpu
		return -1;
	}
}
