// Contains the syscall implementations

module kernel.core.syscall;

import user.syscall;

import kernel.core.error;

import kernel.arch.vmem;

import kernel.environment.scheduler;
import kernel.environment.table;

import kernel.dev.keyboard;
import kernel.dev.vga;

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

    SyscallError makeEnvironment(MakeEnvironmentArgs* params) {
      Scheduler.makeEnvironmentFromGRUBModule(params.id);
      return SyscallError.OK;
    }
}

