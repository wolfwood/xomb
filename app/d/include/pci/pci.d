module pci.pci;

public import pci.header;

typedef ulong pciaddr_t;

struct PciMethods;

static const uint PCI_LIB_VERSION = 0x30100;

struct PciAccess {
  enum Type {
    Auto,
    SysBusPci,
    ProcBusPci,
    I386Type1,
    I386Type2,
    FBSDDevice,
    AIXDevice,
    NBSDLibPci,
    Dump,

    Max
  }

  uint method;		    	/* Access method */
  int  writeable; 			/* Open in read/write mode */
  int  buscentric;			/* Bus-centric view of the world */

  char* id_file_name;		/* Name of ID list file (use pci_set_name_list_path()) */
  int   free_id_name;		/* Set if id_file_name is malloced */
  int   numeric_ids;		/* Enforce PCI_LOOKUP_NUMERIC (>1 => PCI_LOOKUP_MIXED) */

  uint id_lookup_mode;		/* pci_lookup_mode flags which are set automatically */
                 					/* Default: PCI_LOOKUP_CACHE */

  int debugging;			/* Turn on debugging messages */

  /* Functions you can override: */
  void function(char* msg, ...) error;	/* Write error message and quit */
  void function(char* msg, ...) warning;	/* Write a warning message */
  void function(char* msg, ...) _debug;	/* Write a debugging message */

  PciDevice *devices;		/* Devices found on this bus */

  /* Fields used internally: */
  PciMethods* methods;
  PciParam* params;

  void** id_hash;		/* names.c */
  void* current_id_bucket;

  int id_load_failed;
  int id_cache_status;			/* 0=not read, 1=read, 2=dirty */
  int fd;				/* proc/sys: fd for config space */
  int fd_rw;				/* proc/sys: fd opened read-write */
  int fd_pos;				/* proc/sys: current position */
  int fd_vpd;				/* sys: fd for VPD */

  PciDevice* cached_dev;		/* proc/sys: device the fds are for */
}

// Initialize PCI access
extern(C) PciAccess* pci_alloc();
extern(C) void       pci_init(PciAccess*);
extern(C) void       pci_cleanup(PciAccess*);

// Scanning of devices
extern(C) void       pci_scan_bus(PciAccess* acc);
extern(C) PciDevice* pci_get_dev(PciAccess* acc, int domain, int bus, int dev, int func);
extern(C) void        pci_free_dev(PciDevice*);

// Names of access methods
extern(C) int   pci_lookup_method(char *name);	// Returns -1 if not found
extern(C) char* pci_get_method_name(int index);	// Returns "" if unavailable, NULL if index out of range

// Named parameters

struct PciParam {
  PciParam* next;		        // Please use pci_walk_params() for traversing the list
  char*     param;				  // Name of the parameter
  char*     value;			    // Value of the parameter
  int       value_malloced;	// used internally
  char*     help;				    // Explanation of the parameter
}

extern(C) char*     pci_get_param(PciAccess* acc, char *param);
extern(C) int       pci_set_param(PciAccess* acc, char *param, char *value);
extern(C) PciParam* pci_walk_params(PciAccess* acc, PciParam* prev);

// Devices

struct PciDevice {
  PciDevice*   next;
  ushort       domain;
  ubyte        bus, dev, func;

  // These fields are set by pci_fill_info()
  int          known_fields;
  ushort       vendor_id, device_id;
  ushort       device_class;
  int          irq;
  pciaddr_t[6] base_addr;
  pciaddr_t[6] size;
  pciaddr_t    rom_base_addr;
  pciaddr_t    rom_size;
  PciCapability*      first_cap;
  char*        phy_slot;

  // Fields used internally:
  PciAccess*   access;
  PciMethods*  methods;
  ubyte*       cache;
  int          cache_len;
  int          hdrtype;
  void*        aux;
}

static const pciaddr_t PCI_ADDR_IO_MASK   = ~(cast(pciaddr_t)0x3);
static const pciaddr_t PCI_ADDR_MEM_MASK  = ~(cast(pciaddr_t)0xf);
static const pciaddr_t PCI_ADDR_FLAG_MASK =   cast(pciaddr_t)0xf;

extern(C) ubyte  pci_read_byte(PciDevice*, int pos);
extern(C) ushort pci_read_word(PciDevice*, int pos);
extern(C) uint   pci_read_long(PciDevice*, int pos);
extern(C) int    pci_read_block(PciDevice*, int pos, ubyte *buf, int len);
extern(C) int    pci_read_vpd(PciDevice*, int pos, ubyte *buf, int len);
extern(C) int    pci_write_byte(PciDevice*, int pos, ubyte data);
extern(C) int    pci_write_word(PciDevice*, int pos, ushort data);
extern(C) int    pci_write_long(PciDevice*, int pos, uint data);
extern(C) int    pci_write_block(PciDevice*, int pos, ubyte *buf, int len);

extern(C) int    pci_fill_info(PciDevice*, int flags);

static const auto PCI_FILL_IDENT     = 1;
static const auto PCI_FILL_IRQ       = 2;
static const auto PCI_FILL_BASES     = 4;
static const auto PCI_FILL_ROM_BASE  = 8;
static const auto PCI_FILL_SIZES     = 16;
static const auto PCI_FILL_CLASS     = 32;
static const auto PCI_FILL_CAPS      = 64;
static const auto PCI_FILL_EXT_CAPS  = 128;
static const auto PCI_FILL_PHYS_SLOT = 256;
static const auto PCI_FILL_RESCAN    = 0x10000;

extern(C) void pci_setup_cache(PciDevice*, ubyte* cache, int len);

// Capabilities

struct PciCapability {
  PciCapability* next;
  ushort          id;
  ushort          type;
  uint            addr;
}

static const auto PCI_CAP_NORMAL   = 1;
static const auto PCI_CAP_EXTENDED = 2;

extern(C) PciCapability* pci_find_cap(PciDevice*, uint id, uint type);

// Filters

struct PciFilter {
  int domain, bus, slot, func;
  int vendor, device;
}

extern(C) void  pci_filter_init(PciAccess*, PciFilter*);
extern(C) char* pci_filter_parse_slot(PciFilter*, char*);
extern(C) char* pci_filter_parse_id(PciFilter*, char*);
extern(C) int   pci_filter_match(PciFilter*, PciDevice*);

extern(C) char* pci_lookup_name(PciAccess*, char* buf, int size, int flags, ...);

extern(C) int   pci_load_name_list(PciAccess*);
extern(C) void  pci_free_name_list(PciAccess*);
extern(C) void  pci_set_name_list_path(PciAccess*, char *name, int to_be_freed);
extern(C) void  pci_id_cache_flush(PciAccess*);

enum PciLookup {
  VENDOR        = 1,
  DEVICE        = 2,
  CLASS         = 4,
  SUBSYSTEM     = 8,
  PROGIF        = 16,
  NUMERIC       = 0x10000,
  NO_NUMBERS    = 0x20000,
  MIXED         = 0x40000,
  NETWORK       = 0x80000,
  SKIP_LOCAL    = 0x100000,
  CACHE         = 0x200000,
  REFRESH_CACHE = 0x400000,
}
