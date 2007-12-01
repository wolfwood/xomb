/* boot.S - bootstrap the kernel */
/* Copyright (C) 1999, 2001  Free Software Foundation, Inc.

	This program is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the Free Software
	Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA. */

//#ifndef __ELF__
#define EXE_COMPAT_HACK
//#endif

#define ASM     1
#include "multiboot.h"

#define CS_KERNEL 0x10

		.text

		.globl  start, _start
start:
_start:
	.code32
		jmp multiboot_entry

		/* Align 32 bits boundary. */
		.align  4

		/* Multiboot header. */
multiboot_header:
		/* magic */
		.long   MULTIBOOT_HEADER_MAGIC
		/* flags */
		.long   MULTIBOOT_HEADER_FLAGS
		/* checksum */
		.long   -(MULTIBOOT_HEADER_MAGIC + MULTIBOOT_HEADER_FLAGS)

#ifdef EXE_COMPAT_HACK

		/* header_addr */
		.long   multiboot_header
		/* load_addr */
		.long   _start
		/* load_end_addr */
		.long   _edata
		/* bss_end_addr */
		.long   _end
		/* entry_addr */
		.long   multiboot_entry
#endif

multiboot_entry:

		/* Stash values for multiboot we won't touch until 64 bit mode */
		movl %ebx, %esi
		movl %eax, %edi

		/* enable 64-bit page-translation-table entries by
			setting CR4.PAE=1.  Paging not enabled until after
			long mode enabled */
		movl %cr4, %eax
		bts  $5,   %eax
		movl %eax, %cr4

		/* Create long mode page table and init CR3 to point to
			the base of the PML4 page table.  */
		movl $pml4_base, %eax
		movl %eax, %cr3

		/* Enable Long mode and SYSCALL/SYSRET instructions */
		movl $0xc0000080, %ecx
		rdmsr
		bts $8, %eax
		bts $0, %eax
		wrmsr

		/* enable paging to activate long mode */
		movl %cr0, %eax
		bts  $31,  %eax
		movl %eax, %cr0

		or  %edx, %edx
		and %edx, %edx

		/* Load the GDT */
		lgdt	pGDT32

		// make the jump to long mode!
		ljmp $CS_KERNEL, $start64

	.code64
	start64:

		/* Initialize the stack pointer. */
		movq    $(stack + STACK_SIZE), %rsp

		/* Clear cpu flags */
		pushq $0
		popf

// 		sti
// 		call syscall_init


		/* Push the pointer to the Multiboot information structure. */
		pushq   %rsi
		/* Push the magic value. */
		pushq   %rdi

		/* Now enter the C main function... */
		call    EXT_C(cmain)

		/* Halt. */
		/*pushq   $halt_message
		call    EXT_C(kprintf)*/

loop:   hlt
		jmp     loop

/*
#define IA32_STAR  0xC0000081
#define IA32_LSTAR 0xC0000082
#define IA32_FMASK 0xC0000084

// SYSCALL works (If CPUID.80000001.EDX.[bit 11])

syscall_init:
	// check if this shite is supported
	mov $0x80000001,%rax
	cpuid
	and $0x00000400, %edx
	jnz  worky

	//pushq   $syscall_err_message
	//call    EXT_C(kprintString)

	cli
	hlt

worky:
	//mv star,$0x0608020400000000
	mov $0x060802040, %edx
	xor %eax, %eax // zero out eax
	mov  $IA32_STAR, %ecx
	
	//set LSTAR
	//set FMASK

test:
	movq $target, %rcx
	sysretq

target:
	cli

syscall_err_message:
	.asciz  "We require SYSCALL and SYSRET, your CPU isn't cool enough."
*/

halt_message:
	.asciz  "Halted."

pGDT32:
	.word	GDT_END - GDT_TABLE - 1
	.quad	GDT_TABLE

GDT_TABLE:
	.quad	0x0000000000000000	/* NULL descriptor */
	.quad	0x00cf9a000000ffff	/* __KERNEL32_CS */
	.quad	0x00af9a000000ffff	/* __KERNEL_CS */
	.quad	0x0000000000000000	/* upper half of CS */	
	.quad	0x00af93000000ffff	/* __KERNEL_DS */
	.quad	0x0000000000000000	/* upper half of DS */
	.quad	0x00affa000000ffff	/* __USER_CS */
	.quad	0x0000000000000000	/* upper half of CS */
	.quad	0x00aff3000000ffff	/* __USER_DS  */
	.quad	0x0000000000000000	/* upper half of DS */
	.quad	0,0			/* TSS */
	.quad	0,0			/* TSS */
	.quad	0,0			/* LDT */
	.quad	0,0			/* LDT */

	// wtf?
	.quad   0,0,0			/* three TLS descriptors */
	.quad	0x0000f40000000000	/* node/CPU stored in limit */
GDT_END:

.align 4096 // shouldn't be needed
//.globl pml4_base
pml4_base:
	.quad	(level3_ident_pgt + 0x0000000000000007)
	.fill	511,8,0

.align 4096
.globl phys_level2_ident_pgt
	// flags 0x00087

level2_ident_pgt:
	// 40MB for bootup.
	i = 0
	.rept 20
	.quad	i << 21 | 0x083
	i = i + 1
	.endr
	// Temporary mappings for the super early allocator in arch/x86_64/mm/init.c
	.globl temp_boot_pmds

temp_boot_pmds:
	.fill	492,8,0

.align 4096 // shouldn't be needed
.globl phys_level3_ident_pgt

level3_ident_pgt:
	.quad	(level2_ident_pgt + 0x0000000000000007)
	.fill	511,8,0

	// Our stack area.
	.comm   stack, STACK_SIZE
