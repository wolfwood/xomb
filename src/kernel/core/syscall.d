// Contains the syscall implementations

module kernel.core.syscall;

import user.syscall;

import kernel.core.error;

import kernel.arch.vmem;

import kernel.environment.scheduler;
import kernel.environment.table;

import kernel.dev.keyboard;
import kernel.dev.vga;
import kernel.dev.vesa;

struct SyscallImplementations
{

static:
public:

	// Syscall Implementations

	// add two numbers, a and b, and return the result
	// ulong add(long a, long b)
	SyscallError add(out long ret, AddArgs* params)
	{
		ret = params.a + params.b;
		return SyscallError.OK;
	}

	// void allocPage()
	SyscallError allocPage(out void* ret, AllocPageArgs* params)
	{
		//if(vMem.getUserPage(params.va) == ErrorVal.Success)
		//	ret = SyscallError.OK;
		//else
		//	ret = SyscallError.Failcopter;
		Environment* curEnvironment = Scheduler.getCurrentEnvironment();

		ret = curEnvironment.pageTable.allocPages(1);

		//kprintfln!("allocPage: ret: {x}")(ret);

		return SyscallError.OK;
	}

	// void exit(ulong retval)
	SyscallError exit(ExitArgs* params)
	{

		Scheduler.exit();

		return SyscallError.OK;
	}

	SyscallError freePage(FreePageArgs* params)
	{
		Environment* curEnvironment = Scheduler.getCurrentEnvironment();

		curEnvironment.pageTable.freePages(1);

		return SyscallError.OK;
	}

  	SyscallError yield(YieldArgs* params) {
		Scheduler.yield();

		return SyscallError.OK;
	}

	SyscallError error(ErrorArgs* params) {
		Console.printString(params.str, "");
		return SyscallError.OK;
	}

	SyscallError depositKey(DepositKeyArgs* params) {
		Keyboard.depositKey(params.ch);
		return SyscallError.OK;
	}

	SyscallError initKeyboard(out KeyboardInfo ret, InitKeyboardArgs* params) {
		Environment* curEnvironment = Scheduler.getCurrentEnvironment();

		// these are linked to the environment
		ubyte* readable;
		ubyte* writeable;

		// these are linked to RAM directly
		void* virtRead;
		void* virtWrite;

		readable = cast(ubyte*)curEnvironment.pageTable.allocDevicePage(virtRead, false);
		writeable = cast(ubyte*)curEnvironment.pageTable.allocDevicePage(virtWrite, true);

		curEnvironment.deviceUsage |= Environment.Devices.Keyboard;

		// set values
		ret.writePointer = cast(int*)&readable[0];
		ret.buffer = cast(short*)&readable[long.sizeof];
		ret.bufferLength = vMem.PAGE_SIZE - (long.sizeof);

		ret.readPointer = cast(int*)(&writeable[0]);

		KeyboardInfo kInfo;
		readable = cast(ubyte*)virtRead;
		writeable = cast(ubyte*)virtWrite;

		kInfo.writePointer = cast(int*)&readable[0];
		kInfo.buffer = cast(short*)&readable[long.sizeof];
		kInfo.readPointer = cast(int*)(&writeable[0]);

		if (Keyboard.setBuffer(kInfo.buffer, kInfo.readPointer, kInfo.writePointer, ret.bufferLength)
				== ErrorVal.Fail)
		{
			// this means the buffer belongs to somebody else already
			return SyscallError.Failcopter;
		}

		return SyscallError.OK;
	}

	SyscallError initConsole(out ConsoleInfo ret, InitConsoleArgs* params)
	{
		// tell the console that we are giving control away
		if (Console.setBuffer() == ErrorVal.Fail)
		{
			return SyscallError.Failcopter;
		}

		Environment* curEnvironment = Scheduler.getCurrentEnvironment();

		void* virtBuffer; // this IS Console.VideoMem

		// use the second argument to map a page instead of allocate a new page
		ret.buffer = cast(ubyte*)curEnvironment.pageTable.allocDevicePage(virtBuffer, true, vMem.translateAddress(Console.VideoMem));

		ret.xMax = Console.Columns;
		ret.yMax = Console.Lines;

		Console.getPosition(ret.xPos, ret.yPos);

		return SyscallError.OK;
	}

	SyscallError initVESA(out VESAInfo ret, InitVESAArgs* params)
	{
		ubyte* buff;

		Environment* curEnvironment = Scheduler.getCurrentEnvironment();

		// copy over than first page again... we saved it because of the AP code
		VESA.restoreIVT();

		void* virtBuffer;

		// we want a meg? sure, for now
		int i;
		ret.biosRegionLength = 0x100000;
		for (i=0; i<(0xf0000 / vMem.PAGE_SIZE); i++)
		{
			buff = cast(ubyte*)curEnvironment.pageTable.allocDevicePage(virtBuffer, true, cast(void*)(0x0 + (i * vMem.PAGE_SIZE)));

			if (i==0)
			{
				ret.biosRegion = buff;
			}
		}

		// this is for stack space and for retrieving values
		for ( ; i<=(0x100000 / vMem.PAGE_SIZE); i++)
		{
			buff = cast(ubyte*)curEnvironment.pageTable.allocDevicePage(virtBuffer, true);
			//kprintfln!("{x}")(buff);
		}

		ret.int10Addr = cast(ulong)VESA.int10Func;

		return SyscallError.OK;
	}

	// This system call will map a system device within the kernel
	// Maybe this is too much power, and the particular devices have to be supported.

	// XXX: Security must be top priority...although allocating buffers should be acceptable

	// For example of usage, the video card's memory mapped space. (commonly 0xE0000000)
	SyscallError mapDevice(out void* virtAddr, MapDeviceArgs* params)
	{
		ubyte* resultAddr;

		// we need to map it to the calling environment so it can access it

		// get the current environment
		Environment* curEnvironment = Scheduler.getCurrentEnvironment();

		// alloc device pages
		void* virtBuffer;
		ubyte* buff;

		ulong numPages = params.physicalLength / vMem.PAGE_SIZE;
		void* curAddr = params.physicalAddress;

		for (int i = 0; i < numPages; i++)
		{
			// read\write buffer (the user wants it, therefore it is not shared, and therefore no
			//   worries about security of writes.
			buff = cast(ubyte*)curEnvironment.pageTable.allocDevicePage(virtBuffer, true, curAddr);
			kprintfln!("mapDevice: {x} -> {x}")(buff, virtBuffer);

			if (i==0)
			{
				// set the outgoing return to point to the first user page
				virtAddr = cast(void*)buff;
			}

			// increment to next page
			curAddr += vMem.PAGE_SIZE;
		}

		return SyscallError.OK;
	}

	SyscallError makeEnvironment(MakeEnvironmentArgs* params) {
      Scheduler.makeEnvironmentFromGRUBModule(params.id);
      return SyscallError.OK;
    }

}

