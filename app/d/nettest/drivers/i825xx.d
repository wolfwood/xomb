module drivers.i825xx;

import console;

import user.syscall;
import user.environment;
import user.ipc;

class I825xx {
public:
  this(PhysicalAddress base) {
    _base = base;
  }

  void initialize() {
    ulong size = 8 * 1024;

    ubyte[] gib = findFreeSegment(false, size);
    Syscall.makeDeviceGib(gib.ptr, _base, size);
    _registers = cast(e1000Memory*)gib.ptr;
  }

  void macAddress(ubyte[6] mac) {
    ushort read;

    read = eepromRead(0x00);
    mac[0] = read & 0xff;
    mac[1] = read >> 8;

    read = eepromRead(0x01);
    mac[2] = read & 0xff;
    mac[3] = read >> 8;

    read = eepromRead(0x02);
    mac[4] = read & 0xff;
    mac[5] = read >> 8;
  }

private:

  PhysicalAddress _base;

  struct e1000Memory {
    ulong CTRL;
    ulong STATUS;
    uint  EECD;
    uint  EERD;
    uint  CTRL_EXT;
    uint  FLA;
    ulong MDIC;
    uint  FCAL;
    uint  FCAH;
    ulong FCT;
    ulong VET;
  }

  e1000Memory* _registers;

  ushort eepromRead(uint offset) {
    _registers.EERD = (offset << 8) | 0x1;
    uint read;
    while(!((read = _registers.EERD) & (1 << 4))) {
    }
    ushort data = read >> 16;

    return data;
  }
}
