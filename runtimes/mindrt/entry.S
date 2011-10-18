extern UVTbase
				[SECTION .pretext]

header:
				dq 0x0
				dq 0xdeadbeefcafe

global _start
_start:
				mov rax, [UVTbase]
				sal rdi, 3
				add rax, rdi
				jmp [rax]
