; trampoline.s

; entry is at core boot
; the core will boot into 16 bit real mode
; it is the responsibility of this module to jump
; into 32 bit and then 64 bit mode (called trampolining)

section .text
bits 16

%include "defines.mac"

extern _stack
extern pGDT32
extern pml4_base
extern start64_ap

trampoline_start:
_trampoline_start:

	; REAL MODE

	; To appease the conspiracy theorists
	cli

	; establish a stack
	mov sp, (trampoline_stack_end - trampoline_start)

	; clear segment registers
	mov ax, cs
	mov ds, ax
	mov ss, ax
	mov es, ax

	; load 32 bit GDT
	lgdt [p_trampoline_gdt - trampoline_start]

	; set up jump to protected mode
	; by setting the protected mode (PE) bit
	xor ax, ax
	inc ax
	lmsw ax

	; "long" jump into protected mode
	jmp CS_KERNEL32:(trampoline_protected - trampoline_start)

	; end

; Protected Mode

bits 32

trampoline_protected:

	; enable 64-bit page-translation-table entries by
	; setting CR4.PAE=1. Paging is not enabled until after
	; long mode is enabled

	mov eax, cr4
	bts eax, 5
	mov cr4, eax

	; Create long mode page table and init CR3 to point
	; to the bast of the PML4 page table

	mov eax, pml4_base
	mov cr3, eax

	; Enable long mode and SYSCALL/SYSRET instructions
	mov ecx, 0xc0000080
	rdmsr

	xor eax, eax
	bts eax, 8
	bts eax, 0
	wrmsr

	; enable SSE
	mov ecx, cr0
	btr ecx, 2
	bts ecx, 1
	mov cr0, ecx

	mov ecx, cr4
	bts ecx, 9
	bts ecx, 10
	mov cr4, ecx

	; Load the 32 bit GDT
	;lgdt [pGDT32]

	; Load the 32 bit IDT
	; lidt [pIDT32]

	; Set up a stack
	mov esp, (_stack-KERNEL_VMA_BASE) + STACK_SIZE

	; Enable paging to activate long mode
	mov eax, cr0
	bts eax, 31
	mov cr0, eax

	; Jump to long mode
	jmp CS_KERNEL:(start64_ap-KERNEL_VMA_BASE)

	; end

; GDT
align 4096
p_trampoline_gdt:
	dw trampoline_gdt_end - trampoline_gdt - 1
	dq trampoline_gdt - trampoline_start

align 4096
trampoline_gdt:

	dq 0x0000000000000000	; Null Descriptor
	dq 0x00cf9a000000ffff	; CS_KERNEL32
	dq 0x00af9a000000ffff,0	; CS_KERNEL
	dq 0x00af93000000ffff,0	; DS_KERNEL
	dq 0x00affa000000ffff,0	; CS_USER
	dq 0x00aff3000000ffff,0	; DS_USER
	dq 0,0					;
	dq 0,0					;
	dq 0,0					;
	dq 0,0					;

	dq 0,0,0				; Three TLS descriptors
	dq 0x0000f40000000000	;

trampoline_gdt_end:

; STACK
align 4096
trampoline_stack:
align 4096
trampoline_stack_end:
