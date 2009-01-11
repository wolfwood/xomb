# application makefile



# source (edit this)
FILES = intfic.d




# get application name
APPNAME = $(lastword $(subst /application/, , $(shell pwd)))

# compiler binaries
MY_ARCH := $(shell uname)
ifeq (${MY_ARCH}, Darwin)
	DC = x86_64-pc-elf-gdc
	CC = x86_64-pc-elf-gcc
	LD = x86_64-pc-elf-ld
else
	DC = x86_64-pc-elf-gdc
	CC = x86_64-pc-elf-gcc
	LD = x86_64-pc-elf-ld
endif

# flags
DFLAGS = -nostdlib -nodefaultlibs -g -I../../. -I../../runtime/d/libd -I../../libraries -I../.. -J $(shell pwd)
LDFLAGS = -nostdlib -nodefaultlibs -b elf64-x86-64

# object files
OBJS = $(FILES:.d=.o)

# runtime to include
RUNTIME = ../../runtime/d/libd.a

# compile individual code
%.o: %.d
	$(DC) $(DFLAGS) -c $< -o $@

# compile executable
../bin/$(APPNAME): $(OBJS)
	$(LD) $(LDFLAGS) -o $@ -dN $(OBJS) $(RUNTIME)

clean:
	rm -f *.o
	echo $(APPNAME)


veryclean: clean
	rm -f ../bin/$(APPNAME)
