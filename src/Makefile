# Makefile for XOmB

MY_ARCH := $(shell uname)

# default compile options

DC = gdc
CC = gcc
LD = ld
AR = ar

# platform specific options
# NOTE: do we need this? not now, but we may
ifeq (${MY_ARCH},Darwin)
	CC = x86_64-pc-elf-gcc
	LD = x86_64-pc-elf-ld
	DC = x86_64-pc-elf-gdc
	AR = x86_64-pc-elf-ar
	CPFLAGS = -i
else
	CC = x86_64-pc-elf-gcc
	LD = x86_64-pc-elf-ld
	DC = x86_64-pc-elf-gdc
	AR = x86_64-pc-elf-ar
	CPFLAGS = --backup=numbered -u
endif

# applications (specify the directory)
APPS = application1 application2 xsh intfic vesademo

# libOS's (specify the directory)
LIBOS = libconsole libsys libkeyboard libvesa

# flags for assembler
CFLAGS = -nostdlib -nodefaultlibs -g -DUSE_ASSERT -mcmodel=kernel

# flags for gdc
DFLAGS = -nostdlib -nodefaultlibs -g -mcmodel=kernel -fdebug -fno-omit-frame-pointer -J. -I . -I runtime/d/klibd
# flags for ld
LDFLAGS = -nostdlib -nodefaultlibs -b elf64-x86-64 -T linker.ld

# flags for ld, for application link
APP_LDFLAGS = -nostdlib -nodefaultlibs -b elf64-x86-64

# file list
ASM = kernel/arch/x86_64/boot/boot.S kernel/arch/x86_64/boot/load.S kernel/arch/x86_64/boot/trampoline.S

SHELLAPP = $(foreach appdir, $(APPS), cd application/$(appdir) && make && cd ../.. && ) cd .
SHELLLIB = $(foreach osdir, $(LIBOS), cd libos/$(osdir) && make && cd ../.. && ) cd .

ARCHFILES = kernel/arch/x86_64/syscall.d kernel/arch/x86_64/globals.d kernel/arch/x86_64/cpu.d kernel/arch/x86_64/gdt.d kernel/arch/x86_64/lapic.d kernel/arch/x86_64/ioapic.d kernel/arch/x86_64/idt.d kernel/arch/x86_64/vmem.d kernel/arch/x86_64/hpet.d kernel/arch/x86_64/locks.d kernel/arch/x86_64/mp.d kernel/arch/x86_64/pic.d kernel/arch/x86_64/acpi.d kernel/arch/x86_64/timer.d kernel/arch/x86_64/descriptors.d kernel/arch/x86_64/pagefault.d

COREFILES = kernel/core/elf.d kernel/core/syscall.d kernel/core/log.d kernel/kmain.d kernel/dev/vga.d kernel/core/multiboot.d gdb/kgdb_support.d gdb/kgdb_stub.d kernel/core/regions.d kernel/mem/pmem.d config.d kernel/core/error.d kernel/arch/locks.d kernel/dev/keyboard.d kernel/environment/scheduler.d kernel/core/modules.d kernel/environment/table.d kernel/environment/cputable.d kernel/dev/vesa.d runtime/d/klibd/dstubs.d runtime/d/klibd/object.d runtime/d/klibd/invariant.d runtime/d/klibd/system.d kernel/core/util.d $(shell ls runtime/d/klibd/std/typeinfo/*.d)

USERBASE := user/syscall.d kernel/arch/x86_64/usersyscall.d

#APP := application/application.d application/application2.d application/xsh.d application/intfic.d application/vesademo.d
#APP_OBJS = $(APP:.d=.o)
OBJS = $(ASM:.S=.o) $(COREFILES:.d=.o) $(ARCHFILES:.d=.o) $(USERBASE:.d=.o)

RUNTIMEOBJS = $(USERBASE:.d=.o)
SHELLRT = $(foreach rtobj, $(RUNTIMEOBJS), cp $(rtobj) runtime/d/base/. && ) cd .

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
all: setup $(KERNEL_IMG) apps libos
	@echo
	@echo Creating a disassembled dump...
	@echo $(APPFILES)
	rm -f xomb.dump && x86_64-pc-elf-objdump -d -S -r xomb > xomb.dump
	@echo
	@echo OS successfully compiled, to make a bootable CD ISO, run:
	@echo         make iso

# compile applications
apps: libos runtime
	@echo
	@echo Compiling Applications...
	$(SHELLAPP)
	@echo Applications Compiled
	@echo

libos:
	@echo
	@echo Compiling libOSes...
	$(SHELLLIB)
	@echo
	@echo

# assembly compile
.S.o:
	$(CC) $(CFLAGS) -c $< -o $@

# d file compile
%.o: %.d
	$(DC) $(DFLAGS) -c $< -o $@

# kernel link
$(KERNEL_IMG): $(OBJS) runtime
	@echo
	@echo Compiling Kernel...
	$(LD) $(LDFLAGS) -o $@ $(OBJS)
	@echo Kernel Compiled Successfully
	@echo

# compile runtime
runtime: $(RUNTIMEOBJS)
	@echo
	@echo Compiling Runtime...
	# copy object files to base dir for runtime usage
	mkdir -p runtime/d/base
	$(SHELLRT)
	cd runtime/d/libd && make && cd ../../../.
	@echo Runtime Compiled Successfully
	@echo

# creates the GRUB iso image
iso: all
	@echo
	@echo Creating a GRUB iso image...
	mkdir -p $(ISO_PATH)$(GRUB_PATH)
	cp $(GRUB_IMG) $(ISO_PATH)$(GRUB_PATH)
	cp $(GRUB_CONFIG) $(ISO_PATH)$(GRUB_PATH)
	cp $(KERNEL_IMG) $(ISO_PATH)$(BOOT_PATH)
	cp application/bin/* $(ISO_PATH)$(BOOT_PATH)
	mkisofs -R -b $(GRUB_PATH)$(GRUB_IMG) -no-emul-boot -boot-load-size 16 -boot-info-table -o $(ISO_NAME) $(ISO_PATH)
	@echo
	@echo "ISO successfully made!"
	@echo "        qemu-system-x86_64 -cdrom xomb.iso -boot d"
	@echo "     or bochs -q"

# removes .o and the kernel executable
clean:
	@echo
	@echo Removing temporary files
	rm -f $(OBJS) $(KERNEL_IMG)
	rm -f application/bin/*
	rm -f xomb.dump
	rm -f runtime/libd.a
	@echo Clean Performed Successfully
	@echo

# along with the above, removes the files from the iso
# and removes the application executable
veryclean: clean
	@echo
	@echo Removing all files
	rm -rf $(ISO_PATH)
	rm -f $(ISO_NAME)
	rm -f application/bin/*
	@echo Very Clean Performed Successfully
	@echo

# run this after checking out a clean tree
setup: bochsrc config.d

bochsrc: bochsrc.sample
	-cp $(CPFLAGS) bochsrc.sample bochsrc

config.d: config.d.sample
	-cp $(CPFLAGS) config.d.sample config.d
