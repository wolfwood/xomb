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

		/* clear segment registers */
		mov %ax, %ax
		mov %ax, %ds
		mov %ax, %ss

		hlt

		/* turn on paging and protected mode */
		movl $0x80000001, %eax
		mov %eax, %cr0


		nop
		nop





		
		/* "long" jump into protected mode */
		ljmp $0x8, $(trampoline_protected - trampoline_start)








		/* PROTECTED MODE */
		
	.code32

trampoline_protected:

		hlt
		
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
		bts $8, %eax
		bts $0, %eax
		wrmsr 

		/* Load the 32 bit GDT */
		lgdt	(pGDT32)

		/* Load the 32 bit IDT */
		lidt	(pIDT32)

		/* establish a stack for 32 bit code */
		/* mov    $((stack-KERNEL_VMA_BASE) + STACK_SIZE), %esp */

		/* enable paging to activate long mode */
		movl %cr0, %eax
		bts  $31,  %eax
		movl %eax, %cr0

		/* jump to long mode */
		ljmp $CS_KERNEL, $(start64-KERNEL_VMA_BASE)





		/* LONG MODE */

	.code64

		/* just halt */
		hlt

nop
nop
nop
nop
nop
