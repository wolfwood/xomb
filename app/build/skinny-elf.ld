OUTPUT_FORMAT("elf64-x86-64")
ENTRY(_start)

SECTIONS{
				. = 1024*1024*1024;

				.text : {
							*(.pretext);
							*(.text)
							. = ALIGN(4096);
				}
				.rodata : {
							*(.rodata)
							. = ALIGN(4096);
				}
				.data : {
							*(.data)
							. = ALIGN(4096);
				}
				.bss : {
						 bss = .; _bss = .; __bss = .;
						 *(.bss);
				}
				end = .; _end = .; __end = .;
}
