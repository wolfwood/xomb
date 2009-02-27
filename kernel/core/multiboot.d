/* kernel.core.multiboot
 *
 * This file implements the Multiboot Specification
 * which can be found here:
 *
 * http://www.gnu.org/software/grub/manual/multiboot/multiboot.html
 *
 * This means that GRUB (or any other Multiboot compatible
 * boot loader) can load us
 */

module kernel.core.multiboot;

// we want to be able to detect errors.
import kernel.core.error;

import kernel.core.kprintf;

// handleMultibootInformation takes the information that the bootloader gives us
// and then
ErrorVal handleMultibootInformation(int bootLoaderID, void *data) {

  //We need to cast the data to a multiboot_header_t structure. We trust
  //that GRUB is going to give us the correct data, and we don't want to
  //keep those void pointers around for long.
  multiboot_header_t *multiboot_header = cast(multiboot_header_t *)(data);
  kprintfln!("{x}")(multiboot_header.magic);

  //now, we want to verify that that information is correct
  if(verifyMultibootHeader(multiboot_header) == ErrorVal.Fail) {
    return ErrorVal.Fail;
  }

}


// This is an implemenation of the multiboot header structure.
// It is the type of the data that's passed into kmain. You can find
// its reference in the spec here:
// http://www.gnu.org/software/grub/manual/multiboot/multiboot.html#Header-layout
struct multiboot_header_t {

  uint  magic;
  uint flags;
  uint checksum;
  uint header_addr;
  uint load_addr;
  uint load_end_addr;
  uint bss_end_addr;
  uint entry_addr;

};


// This is a 'magic number' that we use to detect if all is well.
// GRUB will pass this number to kmain through the use of the
// multiboot header, and we can test it to verify that things are okay
// http://www.gnu.org/software/grub/manual/multiboot/multiboot.html#Header-magic-fields
const uint MULTIBOOT_HEADER_MAGIC = 0x1BADB002;

const uint MUTLTIBOOT_BOOTLOADER_MAGIC = 0x2BADB002;


// we need to verify that the information that is
// passed in via the multiboot header is correct
ErrorVal verifyMultibootHeader(multiboot_header_t *multiboot_header){

  kprintfln!("{x}, {x}")(multiboot_header.magic, MULTIBOOT_HEADER_MAGIC);
  assert(multiboot_header.magic == MULTIBOOT_HEADER_MAGIC);

  return ErrorVal.Success;
}
