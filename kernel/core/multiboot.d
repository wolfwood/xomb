module kernel.core.multiboot;


// handleMultibootInformation takes the information that the bootloader gives us
// and then
void handleMultibootInformation(int bootLoaderID, void *data) {

  //We need to cast the data to a multiboot_header_t structure. We trust
  //that GRUB is going to give us the correct data, and we don't want to
  //keep those void pointers around for long.
  multiboot_header_t multiboot_header = cast(multiboot_header_t *)(data);


}

// This is an implemenation of the multiboot header structure.
// It is the type of the data that's passed into kmain. You can find
// its reference in the spec here:
// http://www.gnu.org/software/grub/manual/multiboot/multiboot.html#Header-layout
struct multiboot_header_t {

  uint magic;
  uint flags;
  uint checksum;
  uint header_addr;
  uint load_addr;
  uint load_end_addr;
  uint bss_end_addr;
  uint entry_addr;
  uint mode_type;
  uint width;
  uint height;
  uint depth;

};
