# Makefile for XOmB

MY_ARCH := $(shell uname)

# default compile options

DC = gdc
CC = gcc
LD = ld

# platform specific options
# NOTE: do we need this?
ifeq (${MY_ARCH},Darwin)
        CC = x86_64-pc-elf-gcc
        LD = x86_64-pc-elf-ld
	DC = x86_64-pc-elf-gdc
else
	CC = x86_64-pc-elf-gcc
        LD = x86_64-pc-elf-ld
	DC = x86_64-pc-elf-gdc
endif

# flags for assembler
CFLAGS = -nostdlib -nodefaultlibs -g -DUSE_ASSERT -mcmodel=kernel

# flags for gdc
DFLAGS = -nostdlib -nodefaultlibs -g -mcmodel=kernel -fdebug -I . 

# flags for ld
LDFLAGS = -nostdlib -nodefaultlibs -b elf64-x86-64 -T linker.ld

# flags for ld, for application link
APP_LDFLAGS = -nostdlib -nodefaultlibs -b elf64-x86-64 

# file list
ASM = boot.S load.S
DFILES = kernel.d vga.d system.d multiboot.d idt.d gdt.d syscall.d kgdb_support.d vmem.d kgdb_stub.d config.d util.d syscalluser.d
RTFILES := $(shell ls std/typeinfo/*.d) object.d invariant.d dstubs.d std/c/stdarg.d
APP := application.d
OBJS = $(ASM:.S=.o) $(DFILES:.d=.o) $(RTFILES:.d=.o)

# vars
KERNEL_IMG = paganos
GRUB_IMG = stage2_eltorito
GRUB_PATH = boot/grub/
GRUB_CONFIG = menu.lst
BOOT_PATH = boot/
ISO_PATH = iso/
ISO_NAME = paganos.iso

# last task for compile
# will give a disassembled dump
all: $(KERNEL_IMG)
	rm -f paganos.dump && x86_64-pc-elf-objdump -d -S -r paganos > paganos.dump
	@echo ""
	@echo "OS successfully compiled, to make a bootable CD ISO, run:"
	@echo "        make iso"

# assembly compile
.S.o:
	$(CC) $(CFLAGS) -c $<

# d file compile
%.o: %.d
	$(DC) $(DFLAGS) -c $< -o $@

# kernel link
$(KERNEL_IMG): $(OBJS) application.o
	$(LD) $(LDFLAGS) -o $@ $(OBJS)
	$(LD) $(LDFLAGS) -o application application.o -dN $(OBJS)

# creates the GRUB iso image
iso: all
	mkdir -p $(ISO_PATH)$(GRUB_PATH)
	cp $(GRUB_IMG) $(ISO_PATH)$(GRUB_PATH)
	cp $(GRUB_CONFIG) $(ISO_PATH)$(GRUB_PATH)
	cp $(KERNEL_IMG) $(ISO_PATH)$(BOOT_PATH)
	cp ./application $(ISO_PATH)$(BOOT_PATH)
	mkisofs -R -b $(GRUB_PATH)$(GRUB_IMG) -no-emul-boot -boot-load-size 4 -boot-info-table -o $(ISO_NAME) $(ISO_PATH)
	@echo
	@echo "ISO successfully made!"
	@echo "        qemu-system-x86_64 -cdrom paganos.iso -boot d"
	@echo "     or bochs -q"

# removes .o and the kernel executable
clean:
	rm -f $(OBJS) $(KERNEL_IMG) application.o

# along with the above, removes the files from the iso
# and removes the application executable
veryclean: clean
	rm -rf $(ISO_PATH)
	rm -f $(ISO_NAME)
	rm -f ./application
