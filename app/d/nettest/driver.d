module driver;

import drivers.i825xx;

import pci.pci;

import console;

import user.syscall;
import user.environment;
import user.ipc;

class NetworkDriver {
public:
  this() {
    PciAccess* pacc;
    PciDevice* dev;
    uint c;
    char[1024] namebuf;
    char* name;

    pacc = pci_alloc();

    // Initialize the PCI library
    pci_init(pacc);

    // We want to get the list of devices */
    pci_scan_bus(pacc);

    // Iterate over all devices

    for (dev = pacc.devices; dev; dev = dev.next)	{
      // Fill in header info we need
      pci_fill_info(dev, PCI_FILL_IDENT | PCI_FILL_BASES | PCI_FILL_CLASS);

      // Read config register directly
      c = pci_read_byte(dev, PCI_INTERRUPT_PIN);

      /*		printf("%04x:%02x:%02x.%d vendor=%04x device=%04x class=%04x irq=%d (pin %d) base0=%lx\n",
            dev->domain, dev->bus, dev->dev, dev->func, dev->vendor_id, dev->device_id,
            dev->device_class, dev->irq, c, (long) dev->base_addr[0]);*/

      // Look up and print the full name of the device
      if(dev.device_class == 0x0200){
        name = pci_lookup_name(pacc, namebuf.ptr, namebuf.length-1, PciLookup.DEVICE, dev.vendor_id, dev.device_id);

        ulong physaddr = dev.base_addr[0] & ~0xf;

        auto driver = new I825xx(cast(PhysicalAddress)physaddr);

        _name = "i825xx";

        _initialize = &driver.initialize;
        _macAddress = &driver.macAddress;
      }
    }
  }

  void initialize() {
    _initialize();
  }

  void macAddress(ubyte[6] mac) {
    _macAddress(mac);
  }

  char[] name() {
    return _name;
  }

private:
  void delegate()         _initialize;
  void delegate(ubyte[6]) _macAddress;

  char[] _name;
}
