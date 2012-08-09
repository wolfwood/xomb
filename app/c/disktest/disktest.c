/*
 *	The PCI Library -- Example of use (simplistic lister of PCI devices)
 *
 *	Written by Martin Mares and put to public domain. You can do
 *	with it anything you want, but I don't give you any warranty.
 */

#include <stdio.h>
#include <stdlib.h>

#include <pci/pci.h>

#include "sata.c"

void* mapdev(unsigned long long, unsigned long long);

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
		printf("%04x:%02x:%02x.%d vendor=%04x device=%04x class=%04x irq=%d (pin %d) base0=%lx",
					 dev->domain, dev->bus, dev->dev, dev->func, dev->vendor_id, dev->device_id,
					 dev->device_class, dev->irq, c, (long) dev->base_addr[0]);

		/* Look up and print the full name of the device */
		if(dev->device_class == 0x0106){
			name = pci_lookup_name(pacc, namebuf, sizeof(namebuf), PCI_LOOKUP_DEVICE, dev->vendor_id, dev->device_id);
			printf(" (%s)\n", name);


			// map in HBA registers; maximum region size 0x1100
			unsigned long long physaddr = dev->base_addr[5];

			printf("AHCI PCI config space phys addr: %llx\n", physaddr);

			HBA_MEM* abar = mapdev(physaddr, 2*4096);

			printf("win maybe: %llx\n", abar);

			probe_port(abar);


			char* mem = malloc(4096*2);

			mem = mem + 4096 - (((unsigned long long)mem) % 4096);

			printf("alloc: %llx\n", mem);

			// force alloc
			mem[0] = 'a';

			printf("alloc'ed!" );

			if(argc > 1){
				port_rebase(&abar->ports[0], mem);


				char* buf = malloc(4096*4);
				buf = buf + 4096 - (((unsigned long long)buf) % 4096);

				// force alloc
				buf[0] = 'a';


				if(sata_read(&abar->ports[0], 0, 0, 1, buf, mem)){
					printf("WIN\n");

					printf("  output -> ");

					for(int i = 0; i < 4; i++){
						printf(" %x ", buf[i]);
					}

					printf("\n");
				}else{
					printf("\nFAILZ!!\n");
				}
				/*
				if(sata_read(&abar->ports[0], 0, 0, 1, buf, mem)){
					printf("WIN\n");

					printf("  output -> ");

					for(int i = 0; i < 4; i++){
						printf(" %x ", buf[i]);
					}

					printf("\n");
				}else{
					printf("\nFAILZ!!\n");
					}*/
			}
		}
	}
	//pci_cleanup(pacc);		/* Close everything */
	return 0;
}
