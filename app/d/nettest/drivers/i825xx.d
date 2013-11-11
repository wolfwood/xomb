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
    ulong size = 16 * 4 * 1024 * 1024;

    ubyte[] gib = findFreeSegment(false, size);
    Syscall.makeDeviceGib(gib.ptr, _base, size);
    _registers = cast(e1000Memory*)gib.ptr;

    Console.putString("Initializing Transmit Queue\n");
    _initializeQueue();

    Console.putString("Enabling Transmission\n");
    _enableTransmit();

    Console.putString("Link UP\n");
    linkUp();

    Console.putString("Sending packet\n");
    ubyte[] foo = new ubyte[46*4+1];
    send(foo);
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

  void linkUp() {
    static const CTRL_SLU = (1 << 6);

    volatile _registers.CTRL |= (1 << 6);
  }

  void send(ubyte[] data) {
    static const MAX_PACKET_SIZE = 46;

    uint packetCount = data.length / MAX_PACKET_SIZE;
    if ((data.length % MAX_PACKET_SIZE) > 0) {
      packetCount++;
    }
    Console.putInteger(packetCount);
    Console.putString(" packets\n");

    for (uint i = 0; i < packetCount; i++) {
      size_t packetStart = MAX_PACKET_SIZE * i;
      size_t packetEnd   = packetStart + MAX_PACKET_SIZE;
      if (packetEnd > data.length) {
        packetEnd = data.length;
      }

      _send(data[packetStart .. packetEnd]);
    }
  }

private:
  align(1) struct TransmissionDescription {
    ulong  address;

    ushort length;
    ubyte  cso;
    ubyte  cmd;
    ubyte  sta;
    ubyte  css;
    ushort special;
  }

  align(1) struct TransmissionQueue {
    uint TDBAL; // Transmit descriptor base address low
    uint TDBAH; // Transmit descriptor base address high
    uint TDLEN; // Transmit descriptor length - must be multiple of 8 (128 byte cache line / 16 byte descriptor)
    uint xxx;
    uint TDH;   // Transmit descriptor head
    uint xxx2;
    uint TDT;   // Transmit descriptor tail
    uint xxx3;
  }

  align(1) struct EthernetPacket {
    ubyte[6] dest_mac;
    ubyte[6] src_mac;

    ushort pktlen;

    ubyte[46] data;

    uint CRC;
  }

  static const NUM_RX_DESCRIPTORS = 768;
  static const NUM_TX_DESCRIPTORS = 768;

  PhysicalAddress _base;

  TransmissionDescription[] _descriptions;
  PhysicalAddress           _descriptionsLocation;

  TransmissionQueue*        _queue;
  uint                      _queueTail;

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
    volatile _registers.EERD = (offset << 8) | 0x1;
    uint read;
    while(!((read = _registers.EERD) & (1 << 4))) {
    }
    ushort data = read >> 16;

    return data;
  }

  void _allocateTransmissionQueue() {
    if (_descriptions.length > 0) return;
    ulong size = (NUM_TX_DESCRIPTORS * TransmissionDescription.sizeof) + 16;

    ubyte[] transmissionQueue = new ubyte[size];
    ulong queueLocation = cast(ulong)transmissionQueue.ptr;

    TransmissionDescription* transmissionBase = cast(TransmissionDescription*)queueLocation;
    if (queueLocation % 16) {
      transmissionBase = cast(TransmissionDescription*)(queueLocation + 16 - (queueLocation % 16));
    }

    _descriptions = transmissionBase[0 .. NUM_TX_DESCRIPTORS];
    auto phys = cast(void*)getPhysicalAddressOfPage(cast(ubyte*)_descriptions.ptr);
    _descriptionsLocation = cast(PhysicalAddress)(cast(ulong)phys | (cast(ulong)_descriptions.ptr & 0xfff));
  }

  void _initializeQueue() {
    void* address = cast(void*)_registers + 0x3800;
    _queue = cast(TransmissionQueue*)address;

    // Create a Transmission Queue
    _allocateTransmissionQueue();

    // Point to Tranmission Queue
    volatile _queue.TDBAL = cast(uint)_descriptionsLocation;
    volatile _queue.TDBAH = cast(uint)((cast(ulong)_descriptionsLocation) >> 32);
    volatile _queue.TDLEN = _descriptions.length * TransmissionDescription.sizeof;

    // Setup Head and Tail Pointers
    volatile _queue.TDH = 0;
    volatile _queue.TDT = NUM_TX_DESCRIPTORS;

    _queueTail = 0;
  }

  void _enableTransmit() {
    static const TCTL_EN  = (1 << 1);
    static const TCTL_PSP = (1 << 3);

    uint* TCTL = cast(uint*)(cast(void*)_registers + 0x400);
    volatile *TCTL = cast(uint)(TCTL_EN | TCTL_PSP);
  }

  void _send(ubyte[] data) {
    ubyte[] packet = new ubyte[2 * 4096];

    ulong packetLocation = cast(ulong)packet.ptr;
    packetLocation += 4096;
    packetLocation -= packetLocation & 0xfff;

    EthernetPacket* ether = cast(EthernetPacket*)packetLocation;

    for (uint i = 0; i < 6; i++) {
      ether.dest_mac[i] = 0xd;
    }

    macAddress(ether.src_mac);

    ether.pktlen = 46;
    ether.CRC = 0;

    if (data.length < 46) {
      ether.data[0 .. data.length] = data[0 .. $];
    }
    else {
      ether.data[0 .. 46] = data[0 .. 46];
    }

    auto phys = getPhysicalAddressOfPage(cast(ubyte*)packetLocation);

    // Set up the next entry on the queue
    volatile _descriptions[_queueTail].address = cast(uint)phys;
    volatile _descriptions[_queueTail].length  = ether.pktlen;
    volatile _descriptions[_queueTail].cmd     = ((1 << 3) | (3));

    uint tmp;
    volatile tmp = _descriptions[_queueTail].sta;

    // Update the tail of the queue to alert the hardware
    _queueTail = (_queueTail + 1) % _descriptions.length;
    volatile _queue.TDT = _queueTail;

    Console.putString("Sending packet ... ");
    Console.putInteger(tmp);

    uint old_tmp = tmp;

    while (!(tmp & 0xf)) {
      volatile tmp = _descriptions[0].sta;
      if (tmp != old_tmp) {
        Console.putString(" ");
        Console.putInteger(tmp);
        old_tmp = tmp;
      }
    }

    Console.putString("\n");
  }
}
