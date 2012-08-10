/*
 *	The PCI Library -- Example of use (simplistic lister of PCI devices)
 *
 *	Written by Martin Mares and put to public domain. You can do
 *	with it anything you want, but I don't give you any warranty.
 */

#include <stdio.h>
#include <stdlib.h>

#include <pci/pci.h>


typedef unsigned long long ulong;
typedef unsigned short ushort;
typedef unsigned int uint;

struct __attribute__((packed)) e1000_mem {
	ulong CTRL;
	ulong STATUS;
  uint EECD;
  uint EERD;
	uint CTRL_EXT;
	uint FLA;
	ulong MDIC;
	uint FCAL;
	uint FCAH;
	ulong FCT;
	ulong VET;
};

void* mapdev(unsigned long long, unsigned long long);

ushort read_eeprom(struct e1000_mem* abar, unsigned int offset) {
  abar->EERD = (offset << 8) | 0x1;
  uint read;
  while(!((read = abar->EERD) & (1 << 4))) {
    printf("%x\n", read);
  }
  ushort data = read >> 16;
  return data;
}

int main(int argc, char** argv) {
  struct pci_access *pacc;
  struct pci_dev *dev;
  unsigned int c;
  char namebuf[1024], *name;

  pacc = pci_alloc();		/* Get the pci_access structure */
  /* Set all options you want -- here we stick with the defaults */
  pci_init(pacc);		/* Initialize the PCI library */
  pci_scan_bus(pacc);		/* We want to get the list of devices */
  for (dev=pacc->devices; dev; dev=dev->next)	{/* Iterate over all devices */
		pci_fill_info(dev, PCI_FILL_IDENT | PCI_FILL_BASES | PCI_FILL_CLASS);	/* Fill in header info we need */
		c = pci_read_byte(dev, PCI_INTERRUPT_PIN);				/* Read config register directly */
		printf("%04x:%02x:%02x.%d vendor=%04x device=%04x class=%04x irq=%d (pin %d) base0=%lx\n",
					 dev->domain, dev->bus, dev->dev, dev->func, dev->vendor_id, dev->device_id,
					 dev->device_class, dev->irq, c, (long) dev->base_addr[0]);

		/* Look up and print the full name of the device */
		if(dev->device_class == 0x0300){
			name = pci_lookup_name(pacc, namebuf, sizeof(namebuf), PCI_LOOKUP_DEVICE, dev->vendor_id, dev->device_id);
			printf(" (%s)\n", name);

			ulong physaddr = dev->base_addr[0] & ~0xf;

			printf("e1000 PCI config space phys addr: %llx\n", physaddr);

			struct e1000_mem* abar = (struct e1000_mem*)mapdev(physaddr, 8 * 1024);

			printf("win maybe: %llx\n", abar);

      uint data[3];
      data[0] = read_eeprom(abar, 0x00);
      data[1] = read_eeprom(abar, 0x01);
      data[2] = read_eeprom(abar, 0x02);
      data[2] = read_eeprom(abar, 0x04);
      data[2] = read_eeprom(abar, 0x0a);

      printf("data: %x.%x.%x\n", data[0], data[1], data[2]);
		}
	}

	return 0;
}
