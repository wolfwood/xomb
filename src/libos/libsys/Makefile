# libos makefile



# source (edit this)
FILES = lib.d




# get application name
APPNAME = $(lastword $(subst /libos/, , $(shell pwd)))

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
DFLAGS = -nostdlib -nodefaultlibs -g -I../../runtime/d/libd/.
LDFLAGS = -nostdlib -nodefaultlibs -b elf64-x86-64

# object files
OBJS = $(FILES:.d=.o)

# runtime to include
RUNTIME = ../../runtime/d/libd.a

# compile individual code
%.o: %.d
	$(DC) $(DFLAGS) -c $< -o $@

# compile executable
../lib/$(APPNAME): $(OBJS)
	mkdir -p ../lib
	$(AR) rs ../lib/$@ $(OBJS) $(RUNTIME)

clean:
	rm -f *.o
	echo $(APPNAME)


veryclean: clean
	rm -f ../bin/$(APPNAME)
