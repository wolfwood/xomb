// much love to OSdev's http://wiki.osdev.org/AHCI

/* --- from:  http://wiki.osdev.org/IDE --- */
#define ATA_CMD_READ_PIO          0x20
#define ATA_CMD_READ_PIO_EXT      0x24
#define ATA_CMD_READ_DMA          0xC8
#define ATA_CMD_READ_DMA_EXT      0x25
#define ATA_CMD_WRITE_PIO         0x30
#define ATA_CMD_WRITE_PIO_EXT     0x34
#define ATA_CMD_WRITE_DMA         0xCA
#define ATA_CMD_WRITE_DMA_EXT     0x35
#define ATA_CMD_CACHE_FLUSH       0xE7
#define ATA_CMD_CACHE_FLUSH_EXT   0xEA
#define ATA_CMD_PACKET            0xA0
#define ATA_CMD_IDENTIFY_PACKET   0xA1
#define ATA_CMD_IDENTIFY          0xEC

/* --- missing pieces I supplied --- */
typedef unsigned char BYTE;
typedef unsigned char BOOL;
typedef unsigned int DWORD;
typedef unsigned short WORD;

typedef unsigned long long physAddr;

typedef enum {
	AHCI_DEV_NULL = 0x0,
	AHCI_DEV_SATA = 0x1,
	AHCI_DEV_SATAPI = 0x2,
	AHCI_DEV_SEMB = 0x4,
	AHCI_DEV_PM = 0x8,
}AHCI_DEV_TYPE;

#define HBA_PORT_IPM_ACTIVE 1
#define HBA_PORT_DET_PRESENT 0x3

#define trace_ahci printf

#define HBA_PxCMD_CR (1 <<15)
#define HBA_PxCMD_FR (1 <<14)
#define HBA_PxCMD_FRE (1 <<4)
#define HBA_PxCMD_ST (1)

#define cmdslots 8

#define LOBYTE(x) (x & 0xFF)
#define HIBYTE(x) ((x >> 8) & 0xFF)

#define TRUE 1
#define FALSE 0

#define HBA_PxIS_TFES (1 << 30)
#define HBA_PxIS_DHRS (1)

#define HBA_MEM_CAP_S64A (1 << 31)
/* their stuffs */

typedef enum {
	FIS_TYPE_REG_H2D	= 0x27,	// Register FIS - host to device
	FIS_TYPE_REG_D2H	= 0x34,	// Register FIS - device to host
	FIS_TYPE_DMA_ACT	= 0x39,	// DMA activate FIS - device to host
	FIS_TYPE_DMA_SETUP	= 0x41,	// DMA setup FIS - bidirectional
	FIS_TYPE_DATA		= 0x46,	// Data FIS - bidirectional
	FIS_TYPE_BIST		= 0x58,	// BIST activate FIS - bidirectional
	FIS_TYPE_PIO_SETUP	= 0x5F,	// PIO setup FIS - device to host
	FIS_TYPE_DEV_BITS	= 0xA1,	// Set device bits FIS - device to host
} FIS_TYPE;

typedef struct tagFIS_REG_H2D {
	// DWORD 0
	BYTE	fis_type;	// FIS_TYPE_REG_H2D

	BYTE	pmport:4;	// Port multiplier
	BYTE	rsv0:3;		// Reserved
	BYTE	c:1;		// 1: Command, 0: Control

	BYTE	command;	// Command register
	BYTE	featurel;	// Feature register, 7:0

	// DWORD 1
	BYTE	lba0;		// LBA low register, 7:0
	BYTE	lba1;		// LBA mid register, 15:8
	BYTE	lba2;		// LBA high register, 23:16
	BYTE	device;		// Device register

	// DWORD 2
	BYTE	lba3;		// LBA register, 31:24
	BYTE	lba4;		// LBA register, 39:32
	BYTE	lba5;		// LBA register, 47:40
	BYTE	featureh;	// Feature register, 15:8

	// DWORD 3
	BYTE	countl;		// Count register, 7:0
	BYTE	counth;		// Count register, 15:8
	BYTE	icc;		// Isochronous command completion
	BYTE	control;	// Control register

	// DWORD 4
	BYTE	rsv1[4];	// Reserved
} FIS_REG_H2D;

typedef struct tagFIS_REG_D2H {
	// DWORD 0
	BYTE	fis_type;    // FIS_TYPE_REG_D2H

	BYTE	pmport:4;    // Port multiplier
	BYTE	rsv0:2;      // Reserved
	BYTE	i:1;         // Interrupt bit
	BYTE	rsv1:1;      // Reserved

	BYTE	status;      // Status register
	BYTE	error;       // Error register

	// DWORD 1
	BYTE	lba0;        // LBA low register, 7:0
	BYTE	lba1;        // LBA mid register, 15:8
	BYTE	lba2;        // LBA high register, 23:16
	BYTE	device;      // Device register

	// DWORD 2
	BYTE	lba3;        // LBA register, 31:24
	BYTE	lba4;        // LBA register, 39:32
	BYTE	lba5;        // LBA register, 47:40
	BYTE	rsv2;        // Reserved

	// DWORD 3
	BYTE	countl;      // Count register, 7:0
	BYTE	counth;      // Count register, 15:8
	BYTE	rsv3[2];     // Reserved

	// DWORD 4
	BYTE	rsv4[4];     // Reserved
} FIS_REG_D2H;

typedef struct tagFIS_DATA {
	// DWORD 0
	BYTE	fis_type;	// FIS_TYPE_DATA

	BYTE	pmport:4;	// Port multiplier
	BYTE	rsv0:4;		// Reserved

	BYTE	rsv1[2];	// Reserved

	// DWORD 1 ~ N
	DWORD	data[1];	// Payload
} FIS_DATA;

typedef struct tagFIS_PIO_SETUP {
	// DWORD 0
	BYTE	fis_type;	// FIS_TYPE_PIO_SETUP

	BYTE	pmport:4;	// Port multiplier
	BYTE	rsv0:1;		// Reserved
	BYTE	d:1;		// Data transfer direction, 1 - device to host
	BYTE	i:1;		// Interrupt bit
	BYTE	rsv1:1;

	BYTE	status;		// Status register
	BYTE	error;		// Error register

	// DWORD 1
	BYTE	lba0;		// LBA low register, 7:0
	BYTE	lba1;		// LBA mid register, 15:8
	BYTE	lba2;		// LBA high register, 23:16
	BYTE	device;		// Device register

	// DWORD 2
	BYTE	lba3;		// LBA register, 31:24
	BYTE	lba4;		// LBA register, 39:32
	BYTE	lba5;		// LBA register, 47:40
	BYTE	rsv2;		// Reserved

	// DWORD 3
	BYTE	countl;		// Count register, 7:0
	BYTE	counth;		// Count register, 15:8
	BYTE	rsv3;		// Reserved
	BYTE	e_status;	// New value of status register

	// DWORD 4
	WORD	tc;		// Transfer count
	BYTE	rsv4[2];	// Reserved
} FIS_PIO_SETUP;

typedef volatile struct tagHBA_PORT {
	DWORD	clb;		// 0x00, command list base address, 1K-byte aligned
	DWORD	clbu;		// 0x04, command list base address upper 32 bits
	DWORD	fb;		// 0x08, FIS base address, 256-byte aligned
	DWORD	fbu;		// 0x0C, FIS base address upper 32 bits
	DWORD	is;		// 0x10, interrupt status
	DWORD	ie;		// 0x14, interrupt enable
	DWORD	cmd;		// 0x18, command and status
	DWORD	rsv0;		// 0x1C, Reserved
	DWORD	tfd;		// 0x20, task file data
	DWORD	sig;		// 0x24, signature
	DWORD	ssts;		// 0x28, SATA status (SCR0:SStatus)
	DWORD	sctl;		// 0x2C, SATA control (SCR2:SControl)
	DWORD	serr;		// 0x30, SATA error (SCR1:SError)
	DWORD	sact;		// 0x34, SATA active (SCR3:SActive)
	DWORD	ci;		// 0x38, command issue
	DWORD	sntf;		// 0x3C, SATA notification (SCR4:SNotification)
	DWORD	fbs;		// 0x40, FIS-based switch control
	DWORD	rsv1[11];	// 0x44 ~ 0x6F, Reserved
	DWORD	vendor[4];	// 0x70 ~ 0x7F, vendor specific
} HBA_PORT;

typedef volatile struct tagHBA_MEM {
	// 0x00 - 0x2B, Generic Host Control
	DWORD	cap;		// 0x00, Host capability
	DWORD	ghc;		// 0x04, Global host control
	DWORD	is;		// 0x08, Interrupt status
	DWORD	pi;		// 0x0C, Port implemented
	DWORD	vs;		// 0x10, Version
	DWORD	ccc_ctl;	// 0x14, Command completion coalescing control
	DWORD	ccc_pts;	// 0x18, Command completion coalescing ports
	DWORD	em_loc;		// 0x1C, Enclosure management location
	DWORD	em_ctl;		// 0x20, Enclosure management control
	DWORD	cap2;		// 0x24, Host capabilities extended
	DWORD	bohc;		// 0x28, BIOS/OS handoff control and status

	// 0x2C - 0x9F, Reserved
	BYTE	rsv[0xA0-0x2C];

	// 0xA0 - 0xFF, Vendor specific registers
	BYTE	vendor[0x100-0xA0];

	// 0x100 - 0x10FF, Port control registers
	HBA_PORT	ports[1];	// 1 ~ 32
} HBA_MEM;

/*typedef volatile struct tagHBA_FIS{
	// 0x00
	FIS_DMA_SETUP	dsfis;		// DMA Setup FIS
	BYTE		pad0[4];

	// 0x20
	FIS_PIO_SETUP	psfis;		// PIO Setup FIS
	BYTE		pad1[12];

	// 0x40
	FIS_REG_D2H	rfis;		// Register - Device to Host FIS
	BYTE		pad2[4];

	// 0x58
	FIS_DEV_BITS	sdbfis;		// Set Device Bit FIS

	// 0x60
	BYTE		ufis[64];

	// 0xA0
	BYTE		rsv[0x100-0xA0];
} HBA_FIS;
*/
typedef struct tagHBA_CMD_HEADER {
	// DW0
	BYTE	cfl:5;		// Command FIS length in DWORDS, 2 ~ 16
	BYTE	a:1;		// ATAPI
	BYTE	w:1;		// Write, 1: H2D, 0: D2H
	BYTE	p:1;		// Prefetchable

	BYTE	r:1;		// Reset
	BYTE	b:1;		// BIST
	BYTE	c:1;		// Clear busy upon R_OK
	BYTE	rsv0:1;		// Reserved
	BYTE	pmp:4;		// Port multiplier port

	WORD	prdtl;		// Physical region descriptor table length in entries

	// DW1
	volatile
	DWORD	prdbc;		// Physical region descriptor byte count transferred

	// DW2, 3
	DWORD	ctba;		// Command table descriptor base address
	DWORD	ctbau;		// Command table descriptor base address upper 32 bits

	// DW4 - 7
	DWORD	rsv1[4];	// Reserved
} HBA_CMD_HEADER;

typedef struct tagHBA_PRDT_ENTRY {
	DWORD	dba;		// Data base address
	DWORD	dbau;		// Data base address upper 32 bits
	DWORD	rsv0;		// Reserved

	// DW3
	DWORD	dbc:22;		// Byte count, 4M max
	DWORD	rsv1:9;		// Reserved
	DWORD	i:1;		// Interrupt on completion
} HBA_PRDT_ENTRY;

typedef struct tagHBA_CMD_TBL {
	// 0x00
	BYTE	cfis[64];	// Command FIS

	// 0x40
	BYTE	acmd[16];	// ATAPI command, 12 or 16 bytes

	// 0x50
	BYTE	rsv[48];	// Reserved

	// 0x80
	HBA_PRDT_ENTRY	prdt_entry[1];	// Physical region descriptor table entries, 0 ~ 65535
} HBA_CMD_TBL;


#define	SATA_SIG_ATA	0x00000101	// SATA drive
#define	SATA_SIG_ATAPI	0xEB140101	// SATAPI drive
#define	SATA_SIG_SEMB	0xC33C0101	// Enclosure management bridge
#define	SATA_SIG_PM	0x96690101	// Port multiplier


// --- Begin Code ---

// Check device type
static int check_type(HBA_PORT *port){
	DWORD ssts = port->ssts;

	BYTE ipm = (ssts >> 8) & 0x0F;
	BYTE det = ssts & 0x0F;

	if (det != HBA_PORT_DET_PRESENT){	// Check drive status
		//trace_ahci("det = %x, ssts = %x, sact = %d\n", det, ssts, port->sact);
		return AHCI_DEV_NULL;
	}
	if (ipm != HBA_PORT_IPM_ACTIVE){
		//trace_ahci("ipm = %x\n", ipm);
		return AHCI_DEV_NULL;
	}

	switch (port->sig){
	case SATA_SIG_ATAPI:
		return AHCI_DEV_SATAPI;
	case SATA_SIG_SEMB:
		return AHCI_DEV_SEMB;
	case SATA_SIG_PM:
		return AHCI_DEV_PM;
	default:
		return AHCI_DEV_SATA;
	}
}

void probe_port(HBA_MEM *abar){
	if(HBA_MEM_CAP_S64A & abar->cap){
		trace_ahci(" AHCI controller supports 64-bit addresses!\n");
	}else{
		trace_ahci(" 32-bit addresses only!!!!!!!!1111!!!11elventy1!!11\n");
	}
	// Search disk in impelemented ports
	DWORD pi = abar->pi;
	int i = 0;
	while (i<32){
		if (pi & 1){
			int dt = check_type(&abar->ports[i]);
			if (dt == AHCI_DEV_SATA) {
				trace_ahci("SATA drive found at port %d\n", i);
			}else if (dt == AHCI_DEV_SATAPI){
				trace_ahci("SATAPI drive found at port %d\n", i);
			}else if (dt == AHCI_DEV_SEMB){
				trace_ahci("SEMB drive found at port%d\n", i);
			}else if (dt == AHCI_DEV_PM){
				trace_ahci("PM drive found at port %d\n", i);
			}else{
				trace_ahci("No drive found at port %d\n", i);
			}
		}

		pi >>= 1;
		i ++;
	}
}

//#define	AHCI_BASE	0x400000	// 4M


// Start command engine
void start_cmd(HBA_PORT *port){
	trace_ahci(" Starting!\n");

	// Wait until CR (bit15) is cleared
	while (port->cmd & HBA_PxCMD_CR);

	// Set FRE (bit4) and ST (bit0)
	port->cmd |= HBA_PxCMD_FRE;
	port->cmd |= HBA_PxCMD_ST;

	trace_ahci(" Started!\n");
}

// Stop command engine
void stop_cmd(HBA_PORT *port){
	trace_ahci(" Stopping!\n");

	// Clear ST (bit0)
	port->cmd &= ~HBA_PxCMD_ST;

	// Clear FRE (bit4)
	port->cmd &= ~HBA_PxCMD_FRE;

	// Wait until FR (bit14), CR (bit15) are cleared
	while(1){
		if (port->cmd & HBA_PxCMD_FR){
			trace_ahci("  FR\n");
			continue;
		}
		if (port->cmd & HBA_PxCMD_CR){
			trace_ahci("   CR\n");
			continue;
		}
		break;
	}

	trace_ahci(" Stopped!\n");
}

// Find a free command list slot
int find_cmdslot(HBA_PORT *m_port){
	// If not set in SACT and CI, the slot is free
	DWORD slots = (m_port->sact | m_port->ci);
	for (int i=0; i<cmdslots; i++){
		if ((slots&1) == 0){
			printf("   Found Free Slot: %d\n", i);
			return i;
		}
		slots >>= 1;
	}
	trace_ahci("Cannot find free command list entry\n");
	return -1;
}

void* rebasePhysAddr(unsigned long long phys, void* virt){
	void* rebased = virt + (phys % 4096);

	//printf(" BASED: %llx %llx %llx\n", phys, virt, rebased);

	return rebased;
}

void port_rebase(HBA_PORT *port, void* mem){
	physAddr AHCI_BASE = virt2phys(mem);


	printf("is: %x ie: %x\n ssts: %x serr: %x sctl: %x sact: %x sntf: %x\n", port->is, port->ie, port->ssts, port->serr, port->sctl, port->sact, port->sntf);

	printf("\ntfd: %x\n", port->tfd);


	const unsigned int numPorts = 1;
	const unsigned int portno = 0;
	stop_cmd(port);	// Stop command engine

	// Command list offset: 1K*portno
	// Command list entry size = 32
	// Command list entry maxim count = 32
	// Command list maxim size = 32*32 = 1K per port
	port->clb = AHCI_BASE + (portno<<10);
	port->clbu = 0;
	memset(rebasePhysAddr((void*)(port->clb), mem), 0, 1024);

	// FIS offset: 32K+256*portno
	// FIS entry size = 256 bytes per port
	port->fb = AHCI_BASE + (numPorts<<10) + (portno<<8);
	port->fbu = 0;
	memset(rebasePhysAddr((void*)(port->fb), mem), 0, 256);

	// Command table offset: 40K + 8K*portno
	// Command table size = 256*32 = 8K per port
	HBA_CMD_HEADER *cmdheader = (HBA_CMD_HEADER*)rebasePhysAddr((port->clb), mem);
	for (int i=0; i<cmdslots; i++){
		cmdheader[i].prdtl = 8;	// 8 prdt entries per command table
					// 256 bytes per command table, 64+16+48+16*8
		// Command table offset: 40K + 8K*portno + cmdheader_index*256
		cmdheader[i].ctba = AHCI_BASE + (numPorts<<10) + (numPorts<<8) + (portno<<(8 + 3)) + (i<<8);
		cmdheader[i].ctbau = 0;
		memset(rebasePhysAddr((void*)cmdheader[i].ctba, mem), 0, 256);
	}

	start_cmd(port);	// Start command engine
}

unsigned char bitflipper(unsigned char i){
	unsigned char o = 0;

	if(i & 1){
		o |= 128;
	}

	if(i & 2){
		o |= 64;
	}

	if(i & 4){
		o |= 32;
	}

	if(i & 8){
		o |= 16;
	}

	if(i & 16){
		o |= 8;
	}

	if(i & 32){
		o |= 4;
	}

	if(i & 64){
		o |= 2;
	}

	if(i & 128){
		o |= 1;
	}

	return o;
}


BOOL sata_read(HBA_PORT *port, DWORD startl, DWORD starth, DWORD count, WORD *buf, WORD *mem){
	port->is = (DWORD)-1;		// Clear pending interrupt bits

	printf("is: %x ie: %x\n ssts: %x serr: %x sctl: %x sact: %x sntf: %x\n", port->is, port->ie, port->ssts, port->serr, port->sctl, port->sact, port->sntf);

	printf("\ntfd: %x\n", port->tfd);

	int slot = find_cmdslot(port);
	if (slot == -1)
		return FALSE;

	HBA_CMD_HEADER *cmdheader = (HBA_CMD_HEADER*)rebasePhysAddr((port->clb), mem);
	cmdheader += slot;
	cmdheader->cfl = sizeof(FIS_REG_H2D)/sizeof(DWORD);	// Command FIS size
	cmdheader->w = 0;		// Read from device
	cmdheader->prdtl = (WORD)((count-1)>>3) + 1;	// PRDT entries count

	HBA_CMD_TBL *cmdtbl = (HBA_CMD_TBL*)rebasePhysAddr((cmdheader->ctba), mem);
	memset(cmdtbl, 0, sizeof(HBA_CMD_TBL) +
 		(cmdheader->prdtl-1)*sizeof(HBA_PRDT_ENTRY));

	int i;
	// 4K bytes (8 sectors) per PRDT
	for (i=0; i < cmdheader->prdtl-1; i++){
		cmdtbl->prdt_entry[i].dba = (DWORD)virt2phys(buf);
		printf("  <- %llx %llx\n", buf,	cmdtbl->prdt_entry[i].dba);

		cmdtbl->prdt_entry[i].dbc = 4*1024;	// 4K bytes
		cmdtbl->prdt_entry[i].i = 1;
		buf += 1024;	// 1K words
		count -= 8;	// 8 sectors
	}

	// Last entry
	cmdtbl->prdt_entry[i].dba = (DWORD)virt2phys(buf);
	printf("  <- %llx %llx\n", buf,	cmdtbl->prdt_entry[i].dba);
	cmdtbl->prdt_entry[i].dbc = count<<9;	// 512 bytes per sector
	cmdtbl->prdt_entry[i].i = 1;

	// Setup command
	FIS_REG_H2D *cmdfis = (FIS_REG_H2D*)(&cmdtbl->cfis);

	cmdfis->fis_type = FIS_TYPE_REG_H2D;
	cmdfis->c = 1;	// Command
	cmdfis->command = ATA_CMD_READ_DMA;
	//cmdfis->featurel = 1;

	cmdfis->lba0 = (BYTE)startl;
	cmdfis->lba1 = (BYTE)(startl>>8);
	cmdfis->lba2 = (BYTE)(startl>>16);
	cmdfis->device = 1<<6;	// LBA mode

	cmdfis->lba3 = (BYTE)(startl>>24);
	cmdfis->lba4 = (BYTE)starth;
	cmdfis->lba5 = (BYTE)(starth>>8);

	cmdfis->countl = LOBYTE(count);
	cmdfis->counth = HIBYTE(count);

	port->ci = 1<<slot;	// Issue command


	uint err = 0;

	// Wait for completion
	while (1){
		if ((port->ci & (1<<slot)) == 0)
			break;
		if (port->is & HBA_PxIS_TFES){	// Task file error
			trace_ahci("Read disk error 1\n");
			err = 1;
		}
	}

	// Check again
	if (port->is & HBA_PxIS_TFES){
		trace_ahci("Read disk error 2\n");
		err = 1;
	}

	if(err){
		printf("is: %x ie: %x\n ssts: %x serr: %x sctl: %x sact: %x sntf: %x\n", port->is, port->ie, port->ssts, port->serr, port->sctl, port->sact, port->sntf);

		printf("\ntfd: %x\n", port->tfd);

		if(port->is & HBA_PxIS_DHRS){
			void* receivedFIS = rebasePhysAddr((void*)(port->fb), mem);

			FIS_REG_D2H* d2h = receivedFIS + 0x40;

			char* dataz = receivedFIS + 0x40;

			if(d2h->fis_type != FIS_TYPE_REG_D2H){
				printf("Device said it gave us an error D2H FIS, but it lied!\n");
			}else{
				printf("Device gave us a D2H FIS\n");

				for(int i = 0; i < 24; i++){
					printf(" %x", dataz[i]);
				}
			}
		}

		return FALSE;
	}

	return TRUE;
}
