# Makefile for XOmB

svn propset svn:keywords "Revision" kernel/kmain.d

MY_ARCH := $(shell uname)

# default compile options

DC = gdc
CC = gcc
LD = ld

# platform specific options
# NOTE: do we need this? not now, but we may
ifeq (${MY_ARCH},Darwin)
        CC = x86_64-pc-elf-gcc
        LD = x86_64-pc-elf-ld
	DC = x86_64-pc-elf-gdc
	CPFLAGS = -i
else
	CC = x86_64-pc-elf-gcc
        LD = x86_64-pc-elf-ld
	DC = x86_64-pc-elf-gdc
	CPFLAGS = --backup=numbered -u
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
ASM = kernel/arch/x86_64/boot/boot.S kernel/arch/x86_64/boot/load.S kernel/arch/x86_64/boot/trampoline.S
DFILES = kernel/globals.d kernel/arch/x86_64/init.d kernel/log.d kernel/arch/x86_64/gdt.d kernel/dev/lapic.d kernel/dev/ioapic.d kernel/kmain.d kernel/dev/vga.d kernel/core/system.d kernel/core/multiboot.d kernel/arch/x86_64/idt.d kernel/arch/x86_64/syscall.d gdb/kgdb_support.d gdb/kgdb_stub.d kernel/mem/vmem.d kernel/mem/regions.d kernel/mem/pmem.d config.d kernel/core/util.d user/syscall.d kernel/error.d kernel/dev/hpet.d kernel/arch/locks.d kernel/arch/x86_64/locks.d kernel/dev/mp.d kernel/dev/keyboard.d

RTFILES := $(shell ls std/typeinfo/*.d) object.d kernel/core/invariant.d kernel/core/dstubs.d std/c/stdarg.d
APP := application/application.d
OBJS = $(ASM:.S=.o) $(DFILES:.d=.o) $(RTFILES:.d=.o)

# vars
KERNEL_IMG = xomb
GRUB_IMG = stage2_eltorito
GRUB_PATH = boot/grub/
GRUB_CONFIG = menu.lst
BOOT_PATH = boot/
ISO_PATH = iso/
ISO_NAME = xomb.iso

# last task for compile
# will give a disassembled dump
all: setup $(KERNEL_IMG)
	rm -f xomb.dump && x86_64-pc-elf-objdump -d -S -r xomb > xomb.dump
	@echo ""
	@echo "OS successfully compiled, to make a bootable CD ISO, run:"
	@echo "        make iso"

# assembly compile
.S.o:
	$(CC) $(CFLAGS) -c $< -o $@

# d file compile
%.o: %.d
	$(DC) $(DFLAGS) -c $< -o $@

# kernel link
$(KERNEL_IMG): $(OBJS) application/application.o
	$(LD) $(LDFLAGS) -o $@ $(OBJS)
	$(LD) $(LDFLAGS) -o application/application application/application.o -dN $(OBJS)

# creates the GRUB iso image
iso: all
	mkdir -p $(ISO_PATH)$(GRUB_PATH)
	cp $(GRUB_IMG) $(ISO_PATH)$(GRUB_PATH)
	cp $(GRUB_CONFIG) $(ISO_PATH)$(GRUB_PATH)
	cp $(KERNEL_IMG) $(ISO_PATH)$(BOOT_PATH)
	cp ./application/application $(ISO_PATH)$(BOOT_PATH)
	mkisofs -R -b $(GRUB_PATH)$(GRUB_IMG) -no-emul-boot -boot-load-size 4 -boot-info-table -o $(ISO_NAME) $(ISO_PATH)
	@echo
	@echo "ISO successfully made!"
	@echo "        qemu-system-x86_64 -cdrom xomb.iso -boot d"
	@echo "     or bochs -q"

# removes .o and the kernel executable
clean:
	rm -f $(OBJS) $(KERNEL_IMG) application/application.o

# along with the above, removes the files from the iso
# and removes the application executable
veryclean: clean
	rm -rf $(ISO_PATH)
	rm -f $(ISO_NAME)
	rm -f ./application/application

# run this after checking out a clean tree
setup: bochsrc config.d

bochsrc: bochsrc.sample
	-cp $(CPFLAGS) bochsrc.sample bochsrc

config.d: config.d.sample
	-cp $(CPFLAGS) config.d.sample config.d
