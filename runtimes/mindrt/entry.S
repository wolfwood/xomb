extern UVTbase
				[SECTION .pretext]

global _start
_start:
				mov rsi, [UVTbase]
				sal rdi, 3
				add rsi, rdi						
				jmp [rsi]
