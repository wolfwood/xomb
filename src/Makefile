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
DFLAGS = -nostdlib -nodefaultlibs -g -mcmodel=kernel -fdebug -fno-omit-frame-pointer -I .

# flags for ld
LDFLAGS = -nostdlib -nodefaultlibs -b elf64-x86-64 -T linker.ld

# flags for ld, for application link
APP_LDFLAGS = -nostdlib -nodefaultlibs -b elf64-x86-64

# file list
ASM = kernel/arch/x86_64/boot/boot.S kernel/arch/x86_64/boot/load.S kernel/arch/x86_64/boot/trampoline.S

ARCHFILES = kernel/arch/x86_64/syscall.d kernel/arch/x86_64/globals.d kernel/arch/x86_64/cpu.d kernel/arch/x86_64/gdt.d kernel/arch/x86_64/lapic.d kernel/arch/x86_64/ioapic.d kernel/arch/x86_64/idt.d kernel/arch/x86_64/vmem.d kernel/arch/x86_64/hpet.d kernel/arch/x86_64/locks.d kernel/arch/x86_64/mp.d kernel/arch/x86_64/pic.d kernel/arch/x86_64/acpi.d kernel/arch/x86_64/timer.d kernel/arch/x86_64/descriptors.d kernel/arch/x86_64/pagefault.d

COREFILES = kernel/core/elf.d kernel/core/syscall.d kernel/core/log.d kernel/kmain.d kernel/dev/vga.d kernel/core/multiboot.d gdb/kgdb_support.d gdb/kgdb_stub.d kernel/core/regions.d kernel/mem/pmem.d config.d kernel/core/error.d kernel/arch/locks.d kernel/dev/keyboard.d kernel/environment/scheduler.d kernel/core/modules.d kernel/environment/table.d kernel/environment/cputable.d

RTFILES := $(shell ls std/typeinfo/*.d) object.d kernel/core/invariant.d user/libd.d std/c/stdarg.d kernel/core/system.d user/syscall.d kernel/core/util.d kernel/arch/x86_64/usersyscall.d user/malloc.d user/basicio.d std/stdarg.d

APP := application/application.d application/application2.d application/xsh.d
APP_OBJS = $(APP:.d=.o)
OBJS = $(ASM:.S=.o) $(COREFILES:.d=.o) $(RTFILES:.d=.o) $(ARCHFILES:.d=.o)

RUNTIMEOBJS = $(RTFILES:.d=.o)

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
	rm -f application.dump && x86_64-pc-elf-objdump -d -S -r application/application > application/application.dump
	rm -f application2.dump && x86_64-pc-elf-objdump -d -S -r application/application2 > application/application2.dump
	rm -f xsh.dump && x86_64-pc-elf-objdump -d -S -r application/xsh > application/xsh.dump
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
$(KERNEL_IMG): $(OBJS) $(APP_OBJS)
	$(LD) $(LDFLAGS) -o $@ $(OBJS)
	$(LD) $(APP_LDFLAGS) -o application/application application/application.o -dN $(RUNTIMEOBJS)
	$(LD) $(APP_LDFLAGS) -o application/application2 application/application2.o -dN $(RUNTIMEOBJS)
	$(LD) $(APP_LDFLAGS) -o application/xsh application/xsh.o -dN $(RUNTIMEOBJS)

# creates the GRUB iso image
iso: all
	mkdir -p $(ISO_PATH)$(GRUB_PATH)
	cp $(GRUB_IMG) $(ISO_PATH)$(GRUB_PATH)
	cp $(GRUB_CONFIG) $(ISO_PATH)$(GRUB_PATH)
	cp $(KERNEL_IMG) $(ISO_PATH)$(BOOT_PATH)
	cp ./application/application $(ISO_PATH)$(BOOT_PATH)
	cp ./application/application2 $(ISO_PATH)$(BOOT_PATH)
	cp ./application/xsh $(ISO_PATH)$(BOOT_PATH)
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
