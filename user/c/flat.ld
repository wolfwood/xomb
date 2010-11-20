OUTPUT_FORMAT("binary") /*elf64-x86-64")*/
ENTRY(_start)

SECTIONS{
				. = 1024*1024*1024;

				.text : {
							*(.pretext);
							*(.text)
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