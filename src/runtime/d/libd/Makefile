# Makefile for libd

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

DFLAGS = -I ../../../. -I../../../libraries/.

FILES = object.d invariant.d libd.d std/c/stdarg.d system.d util.d heap.d basicio.d std/stdarg.d $(shell ls std/typeinfo/*.d) ../../../libos/libconsole/console.d ../../../libos/libkeyboard/keyboard.d ../../../libos/libvesa/vesa.d ../../../libraries/xombemu/x86emu.d ../../../libraries/xombemu/x86/fetch.d ../../../libraries/xombemu/x86/memory.d ../../../libraries/xombemu/x86/registers.d ../../../libraries/xombemu/x86/opcodes.d ../../../libraries/xombemu/x86/stack.d ../../../libraries/xombemu/x86/interrupt.d ../../../libraries/xombemu/x86/exception.d


OBJS = $(FILES:.d=.o) $(shell ls ../base/*.o)

%.o: %.d
	$(DC) $(DFLAGS) -c $< -o $@

libd.a: $(OBJS)
	$(AR) rs ../libd.a $(OBJS)

clean:
	rm -f $(OBJS)

veryclean: clean
	rm -f ../libd.a
