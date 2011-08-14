extern UVTbase
				[SECTION .pretext]

header:
				dq 0x0
				dq 0xdeadbeefcafe

global _start
_start:
				mov rsi, [UVTbase]
				sal rdi, 3
				add rsi, rdi
				jmp [rsi]
