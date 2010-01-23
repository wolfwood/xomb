bits 64

section .text

extern main

global _start
global start

start:
_start:

	call main

_loop:
	jmp _loop
