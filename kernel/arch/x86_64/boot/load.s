; load.s

; entry is from boot.s

bits 64

; Everywhere you see some weird addition logic
; This is to fit the addresses into 32 bit sizes
; Note, they will sign extend!

section .text

; where is the kernel?
%define KERNEL_VMA_BASE			0xFFFFFFFF80000000
%define KERNEL_LMA_BASE			0x100000

; the gdt entry to use for the kernel
%define CS_KERNEL				0x10
%define CS_KERNEL32				0x08

%define STACK_SIZE				0x4000

; extern to kmain.d
extern kmain

global start64

start64:

	; Initialize the 64 bit stack pointer.
	mov rsp, ((stack - KERNEL_VMA_BASE) + STACK_SIZE)

	; Set up the stack for the return.
	push CS_KERNEL
	push (long_entry-KERNEL_VMA_BASE) + (KERNEL_VMA_BASE & 0xffffffff)

	; Go into canonical higher half
	; It uses a trick to update the program counter
	;   across a 64 bit address space
	ret

long_entry:

	; From here on out, we are running instructions
	; within the higher half (0xffffffff80000000 ... )

	; We can safely upmap the lower half, we do not
	; need an identity mapping of this region

	; set up a 64 bit virtual stack
	mov rsp, (stack-KERNEL_VMA_BASE) + STACK_SIZE + (KERNEL_VMA_BASE & 0xffffffff)

	; set cpu flags
	push 0
	lss eax, [rsp]
	popf

	; set the input/output permission level to 3
	; it will allow all access

	pushf
	pop rax
	or rax, 0x3000
	push rax
	popf

	; update the multiboot struct to point to a
	; virtual address
	add rsi, (KERNEL_VMA_BASE & 0xffffffff)

	; push the parameters (just in case)
	push rsi
	push rdi

	; call kmain
	call kmain



	; we should not get here

haltloop:

	hlt
	jmp haltloop
	nop
	nop
	nop



; stack space
global stack
align 4096

stack:
	%rep STACK_SIZE
	dd 0
	%endrep

