# library makefile



# source (edit this)
FILES = x86emu.d x86/fetch.d x86/memory.d x86/registers.d x86/opcodes.d x86/stack.d x86/interrupt.d x86/exception.d




# get application name
APPNAME = $(lastword $(subst /libraries/, , $(shell pwd)))

# compiler binaries
MY_ARCH := $(shell uname)
ifeq (${MY_ARCH}, Darwin)
	DC = x86_64-pc-elf-gdc
	CC = x86_64-pc-elf-gcc
	LD = x86_64-pc-elf-ld
	AR = x86_64-pc-elf-ar
else
	DC = x86_64-pc-elf-gdc
	CC = x86_64-pc-elf-gcc
	LD = x86_64-pc-elf-ld
	AR = x86_64-pc-elf-ar
endif

# flags
DFLAGS = -nostdlib -nodefaultlibs -g -I../../runtime/d/libd/. -I../. -I../../.
LDFLAGS = -nostdlib -nodefaultlibs -b elf64-x86-64

# object files
OBJS = $(FILES:.d=.o)

# runtime to include
#RUNTIME =

# compile individual code
%.o: %.d
	$(DC) $(DFLAGS) -c $< -o $@

# compile executable
../lib/$(APPNAME): $(OBJS)
	mkdir -p ../lib
	$(AR) rs ../lib/$(APPNAME).a $(OBJS) $(RUNTIME)

clean:
	rm -f $(OBJS)

veryclean: clean
	rm -f ../lib/$(APPNAME).a
