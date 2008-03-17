module gdb.kgdb_support;

static import kernel.idt;

const byte *com1 = cast(byte*)0x3f8;
const byte *com2 = cast(byte*)0x2f8;

byte *combase = com1;

void init_serial()
{
	//	outb(inb(combase + 3) | 0x80, combase + 3);
	volatile *(combase +3) = *(combase + 3) | 0x80;

	//	outb(12, combase);		 /* 9600 bps, 8-N-1 */
	volatile *(combase) = 12;

	//	outb(0, combase+1);
	volatile *(combase+1) = 0;

	//	outb(inb(combase + 3) & 0x7f, combase + 3);
	volatile *(combase +3) = *(combase + 3) & 0x7f;
}

ubyte getDebugChar()
{
	volatile while (!(*(combase + 5) & 0x01)){}
	return *combase;
}

void putDebugChar(ubyte ch)
{
	volatile while (!( *(combase + 5) & 0x20)){}
	volatile *(combase) = cast (ubyte) ch;
}

/* void exceptionHandler(int exc, void *addr)
{
	idt.setIntGate(exc, addr);
} */

// make this point at our exception handler, so gdb can call it on page faults
//void (*exceptionHook)() = 0;

void flush_i_cache()
{
	asm{"jmp 1f\n1:";}
}

/* 
void *memset(void *ptr, int val, unsigned int len); 

	 needs to be defined if it hasn't been already
*/
