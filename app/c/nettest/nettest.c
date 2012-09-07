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
typedef unsigned int       uint;
typedef unsigned short     ushort;
typedef unsigned char      ubyte;

struct __attribute__((packed)) e1000_mem {
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
};

struct __attribute__((packed)) I350_mem {
	ulong CTRL; // 0x0000
	ulong STATUS; // 0x0008
  uint  EEC;
  uint  EERD; //0x14
	uint  CTRL_EXT;
	uint  FLA;
	ulong MDIC;
	uint  FCAL;
	uint  FCAH;
	uint  FCT;
	uint  CONNSW;
	ulong VET;
};

void* mapdev(unsigned long long, unsigned long long);

ushort read_eeprom(struct e1000_mem* abar, uint offset) {
  abar->EERD = (offset << 8) | 0x1;
  uint read;
  while(!((read = abar->EERD) & (1 << 4))) {
    printf("%x\n", read);
  }
  ushort data = read >> 16;
  return data;
}

ushort read_eeprom_I350(struct I350_mem* abar, uint offset) {
  abar->EERD = ((offset << 2) | 0x0001);
  uint read;
  while(!((read = abar->EERD) & (0x0002))) {
		if(read != 0){
			printf("%x\n", read);
		}
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
		if(dev->device_class == 0x0200){
			name = pci_lookup_name(pacc, namebuf, sizeof(namebuf), PCI_LOOKUP_DEVICE, dev->vendor_id, dev->device_id);
			printf(" (%s)\n", name);

			if(dev->vendor_id == 0x8086 && dev->device_id == 0x100e){
				ulong physaddr = dev->base_addr[0] & ~0xf;


				printf("e1000 PCI config space phys addr: %llx\n", physaddr);

				struct e1000_mem* abar = (struct e1000_mem*)mapdev(physaddr, 8 * 1024);

				printf("win maybe: %llx\n", abar);

				ubyte  mac[6];
				ushort read;

				read = read_eeprom(abar, 0x00);
				mac[0] = read & 0xff;
				mac[1] = read >> 8;

				read = read_eeprom(abar, 0x01);
				mac[2] = read & 0xff;
				mac[3] = read >> 8;

				read = read_eeprom(abar, 0x02);
				mac[4] = read & 0xff;
				mac[5] = read >> 8;

				printf("mac: %.2x:%.2x:%.2x:%.2x:%.2x:%.2x\n", mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);


				// set link UP flag
				abar->CTRL |= 1<< 6;





			}else if(dev->vendor_id == 0x8086 && dev->device_id == 0x1520){
				printf("\tFOUND DAT VF\n");
				ulong physaddr = dev->base_addr[0] & ~0xf;

				printf("I350 PCIe config space phys addr: %llx\n", physaddr);
				struct I350_mem* abar = (struct I350_mem*)mapdev(physaddr, 8 * 1024);

				// MAC
				printf("win maybe: %llx CTRL: %llx STS: %llx\n", abar, abar->CTRL, abar->STATUS);

				ubyte  mac[6];
				ushort read;

				uint lanOffset = ((abar->STATUS >> 2) & 0x3);

				switch(lanOffset){
				case 1:
					lanOffset = 0x80;
					break;
				case 2:
					lanOffset = 0xC0;
					break;
				case 3:
					lanOffset = 0x100;
					break;
				default:
					lanOffset = 0;
				}


				printf("  Port offset: %x\n",lanOffset);

				read = read_eeprom_I350(abar, lanOffset + 0x00);
				mac[0] = read & 0xff;
				mac[1] = read >> 8;

				read = read_eeprom_I350(abar, lanOffset + 0x01);
				mac[2] = read & 0xff;
				mac[3] = read >> 8;

				read = read_eeprom_I350(abar, lanOffset + 0x02);
				mac[4] = read & 0xff;
				mac[5] = read >> 8;

				printf("mac: %.2x:%.2x:%.2x:%.2x:%.2x:%.2x\n", mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);


				// disable interrupts


				// Global Reset

				// disable interrupts

				// Configuration


				// Set up PHY and link


				// Init rx


				// Init tx


				// enable interrupts

			}
		}
	}

	return 0;
}
