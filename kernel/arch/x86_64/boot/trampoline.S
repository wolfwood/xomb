// trampoline.S
// -----------------
// This file contains the code for starting application processors in a
// multiprocessor environment.  It starts in 16 bit Real Mode and should
// end up in long mode before running kernel code.

#include "boot.h"

trampoline_start:
_trampoline_start:

	.code16

		/* REAL MODE */
 
		/* to appease conspiracy theorists */
		cli		

		/* set the stack */
		mov (trampoline_stack_end - trampoline_start), %sp

		/* clear segment registers */
		mov %cs, %ax
		mov %ax, %ds
		mov %ax, %ss
		mov %ax, %es

		/* Load the 32 bit GDT */
		lgdt	(p_trampoline_gdt - trampoline_start)

		nop
		nop


	 	xor	%ax, %ax
	 	inc	%ax		# protected mode (PE) bit
	 	lmsw	%ax		# into protected mode

		/* "long" jump into protected mode */
		ljmp $CS_KERNEL32, $(trampoline_protected - trampoline_start)

		/* GDT */



/* GDT */

	.align 4096
	.globl p_trampoline_gdt
p_trampoline_gdt:
	.word	trampoline_gdt_end - trampoline_gdt - 1
	.quad	trampoline_gdt - trampoline_start

.align 4096
trampoline_gdt:
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
trampoline_gdt_end:







/* STACK */
.align 4096
trampoline_stack:
	.comm trampoline__stack, 4096
trampoline_stack_end:











		/* PROTECTED MODE */
		
	.code32
trampoline_protected:
		
		/* enable 64-bit page-translation-table entries by
			setting CR4.PAE=1.  Paging not enabled until after
			long mode enabled */
		movl %cr4, %eax
		bts  $5,   %eax
		movl %eax, %cr4

		/* Create long mode page table and init CR3 to point to
			the base of the PML4 page table.  */
		movl $(pml4_base), %eax
		movl %eax, %cr3

		/* Enable Long mode and SYSCALL/SYSRET instructions */
		movl $0xc0000080, %ecx
		rdmsr

		xor %eax, %eax
		bts $8, %eax
		bts $0, %eax
		wrmsr 

		/* Load the 32 bit GDT */
		//lgdt	(pGDT32)

		/* Load the 32 bit IDT */
	//	lidt	(pIDT32)
//		hlt

		/* establish a stack for 32 bit code */
		//mov    $((stack-KERNEL_VMA_BASE) + STACK_SIZE), %esp

		/* enable paging to activate long mode */
		movl %cr0, %eax
		bts  $31,  %eax
		movl %eax, %cr0

		/* jump to long mode */
		ljmp $CS_KERNEL, $(start64_ap - KERNEL_VMA_BASE)

		/* LONG MODE */

nop
nop
nop
nop
nop
