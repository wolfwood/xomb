/* our implemetation of an x86_64 stub for gdb kernel debugging over
	 serial line, in D.  Keep content in this file in line with the
	 XXX-stub.c file from gdb, put stuff specific to our project in
	 kgdb_support.d
*/

/*		The following gdb commands are supported:
 *
 * command				function								Return value
 *
 *		g 				return the value of the CPU registers  	hex data or ENN
 *		G 				set the value of the CPU registers		OK or ENN
 *
 *		mAA..AA,LLLL	Read LLLL bytes at address AA..AA 		hex data or ENN
 *		MAA..AA,LLLL: 	Write LLLL bytes at address AA.AA 		OK or ENN
 *
 *		c 				Resume at current address 				SNN	 ( signal NN)
 *		cAA..AA 		Continue at address AA..AA				SNN
 *
 *		s 				Step one instruction					SNN
 *		sAA..AA 		Step one instruction from AA..AA		SNN
 *
 *		k 				kill
 *
 *		? 				What was the last sigval ?				SNN	 (signal NN)
 *
 * All commands and responses are sent with a packet which includes a
 * checksum.	A packet consists of
 *
 * $<packet info>#<checksum>.
 *
 * where
 * <packet info> :: <characters representing the command or response>
 * <checksum> 	 :: <two hex digits computed as modulo 256 sum of <packetinfo>>
 *
 * When a packet is received, it is first acknowledged with either '+' or '-'.
 * '+' indicates a successful transfer.  '-' indicates a failed transfer.
 *
 * Example:
 *
 * Host:									Reply:
 * $m0,10#2a							 +$00010203040506070809101112131415#42
 *
 */

// get a number of support functions
import gdb.kgdb_support;

import idt = kernel.arch.x86_64.idt;
import kernel.dev.vga;

import config;

import kernel.core.util;
import kernel.core.system;

// --- Create  Debug ISRs ---
// we want to capture exceptions 0, 1, 3, 4-10, 12, 16
// double check for memory fault (could be cause by debugger) on 11, 13, 14

// --- Debug ISR Handler ---

struct int_stack_gdb
{
	long rax, rdx, rcx, rbx, rsi, rdi, rbp, rsp, r8;
	long r9, r10, r11, r12, r13, r14, r15, rip, rflags;
}

int_stack_gdb tempStack;

bool initialized = false;
bool mem_err = false;

static const public auto BUFMAX = 400;

ubyte[BUFMAX] inMessage;
ubyte[BUFMAX] outMessage;

void setMessage(char[] msg...)
{
	assert(msg.length <= outMessage.length, "setMessage message too long");

	outMessage[0 .. msg.length] = cast(ubyte[])msg[];
	outMessage[msg.length] = 0;
}

void handle_exception(idt.interrupt_stack* ir_stack){

	// If kgdb remote (target) debugging is on
	if (remote_debug)
		kprintfln!("vector={}, sr=0x{x}, pc=0x{x}\n")(ir_stack.int_no,
							ir_stack.rsp, ir_stack.rip);

	// Signal value (interrupt in terms of a unix signal value)
	int sigval = computeSignal(ir_stack.int_no);
	setMessage('S', hexchars[sigval >> 4], hexchars[sigval % 16]);
	putpacket(outMessage);

	while(true){
		int error = 0;
		outMessage[0] = 0;
		getpacket(inMessage);

		switch(inMessage[0]){
		case '?' : 
			setMessage('S', hexchars[sigval >> 4], hexchars[sigval % 16]);
			break;
			
		case 'd' : // toggle remote debugging messages
			remote_debug = !remote_debug; // Toggle debug flag
			break;
			
		case 'g':  // return the value of the CPU regs
			regs2gdb(ir_stack);
			mem2hex(outMessage, toByteArray(&tempStack));
			break;
			
		case 'G':  // set CPU regs
			regs2gdb(ir_stack); // populate in case gdb doesn't send all the regs
			hex2mem(toByteArray(&tempStack), inMessage);
			gdb2regs(ir_stack);
			break;

			/* mAA..AA,LLLL  Read LLLL bytes at address AA..AA */
		case 'm' :
			bool sucess = false;
			auto tempArray = inMessage[1 .. $];
			ulong addr, numBytes;
			if(hex2long(tempArray, addr) != 0){
				if(tempArray[0] == ','){
					tempArray = tempArray[1 .. $];
					if(hex2long(tempArray, numBytes) != 0){
						sucess = true;
						mem_err = false;
						mem2hex(toByteArray(&addr, numBytes), outMessage, true);
						
						if(mem_err){
							setMessage("E03");
							if (remote_debug) kprintfln!("Memory Fault.")();
						}
					}
				}
			}

			if(sucess){
				setMessage("E01");

				if (remote_debug)
					kprintfln!("Malformed read memory command: {}")(toString(cast(char*)inMessage.ptr));
			}
			break;
			
			/* MAA..AA,LLLL: Write LLLL bytes at address AA.AA return OK */
		case 'M':
			bool sucess = false;
			auto tempArray = inMessage[1 .. $];
			ulong addr;
			size_t numBytes;
			
			if(hex2long(tempArray, addr) != 0){
				if(tempArray[0] == ','){
					tempArray = tempArray[1 .. $];
					if(hex2long(tempArray, numBytes) != 0){
						if(tempArray[0] == ':'){
							tempArray = tempArray[1 .. $];
							tempArray.length = numBytes;

							mem_err = false;
							hex2mem(tempArray, toByteArray(cast(void*)addr, numBytes), true);

							if(mem_err){
								setMessage("E03");
								if (remote_debug) kprintfln!("Memory Fault.")();
							}else{
								setMessage("OK");
							}
							sucess = true;
						}
					}
				}
			}

			if(sucess){
				setMessage("E02");

				if (remote_debug)
					kprintfln!("Malformed read memory command: {}")(toString(cast(char*)inMessage.ptr));
			}

			break;

			/* cAA..AA		Continue at address AA..AA(optional) */
			/* sAA..AA	 Step one instruction from AA..AA(optional) */
		case 'c' :
		case 's' :
			auto tempArray = inMessage[1 .. $];
			ulong addr;
			if(hex2long(tempArray, addr) != 0){
				ir_stack.rip = addr; // set the
			}
			
			// Call original handler?

			/// return from exception
			return;

		case 'k':
			break;
		}

		/* reply */
		putpacket(outMessage);
	}
}

// --- For Kernel ---

void breakpoint(){
	if (initialized)
		asm{int 3;}

	waitabit();
}

void set_debug_traps(){

	// set up exception handler for 0,1,3-14,16, using an IST stack
	// also remember the old handler?

	idt.setCustomHandler(idt.Type.DivByZero,		&handle_exception);
	idt.setCustomHandler(idt.Type.Debug,			&handle_exception);
	idt.setCustomHandler(idt.Type.Breakpoint,		&handle_exception);
	idt.setCustomHandler(idt.Type.INTO,				&handle_exception);
	idt.setCustomHandler(idt.Type.OutOfBounds,		&handle_exception);
	idt.setCustomHandler(idt.Type.InvalidOpcode,	&handle_exception);
	idt.setCustomHandler(idt.Type.NoCoproc,			&handle_exception);
	idt.setCustomHandler(idt.Type.DoubleFault,		&handle_exception);
	idt.setCustomHandler(idt.Type.CoprocSegOver,	&handle_exception);
	idt.setCustomHandler(idt.Type.BadTSS,			&handle_exception);
	idt.setCustomHandler(idt.Type.SegNotPresent,	&handle_exception);
	idt.setCustomHandler(idt.Type.StackFault,		&handle_exception);
	idt.setCustomHandler(idt.Type.GPF,				&handle_exception);
	idt.setCustomHandler(idt.Type.PageFault,		&handle_exception);
	idt.setCustomHandler(idt.Type.CoprocFault,		&handle_exception);

	initialized = true;
}

// --- Debug Serial I/O ---

void getpacket(ubyte[] packet){
	ubyte checksum, xmitcsum, ch;
	int i, count;

	do {
		/* wait around for the start character, ignore all other characters */
		while ((ch = (getDebugChar() & 0x7f)) != '$'){}
		checksum = 0;
		xmitcsum = 0xFF;

		count = 0;

		/* now, read until a # or end of buffer is found */
		while (count < BUFMAX) {
			ch = getDebugChar() & 0x7f;
			if (ch == '#') break;
			checksum += ch;
			packet[count] = ch;
			count = count + 1;
		}

		packet[count] = 0;

		if (ch == '#') {
			xmitcsum = hexchar2byte(getDebugChar() & 0x7f) << 4;
			xmitcsum += hexchar2byte(getDebugChar() & 0x7f);

			if(checksum != xmitcsum){
				putDebugChar('-');	/* failed checksum */

				if(remote_debug){
					kprintf!("bad checksum.  My count = 0x{x}, sent=0x{x}. buf={}\n")(
									 checksum, xmitcsum, packet.ptr);
				}
			}else{
				putDebugChar('+');	/* successful transfer */

				// XXX: wtf is this?
				/* if a sequence char is present, reply the sequence ID */
				if (packet[2] == ':') {
					putDebugChar( packet[0] );
					putDebugChar( packet[1] );

					/* remove sequence chars from buffer */;
					for (i=3; i <= count; i++){
						packet[i-3] = packet[i];
					}
				}
			}
		}
	} while (checksum != xmitcsum);
}

void putpacket(ubyte[] packet){
	ubyte checksum, ch;
	int count;

	/*	$<packet info>#<checksum>. */
	do {
		putDebugChar('$');
		checksum = 0;
		count 	 = 0;

		while ((ch = packet[count]) != 0) {
			putDebugChar(ch);
			checksum += ch;
			count++;
		}

		putDebugChar('#');
		putDebugChar(hexchars[checksum >> 4]);
		putDebugChar(hexchars[checksum % 16]);

	} while ((getDebugChar() & 0x7f) != '+');
}

// --- Helpers ---

//	Used to treat a memory region (or struct) as a byte array
ubyte[] toByteArray(T)(T t, size_t len = 0)
{
	static if(is(typeof(t.ptr)))
		return (cast(ubyte*)t.ptr)[0 .. t.length];
	else static if(is(typeof(*t)) || is(T == void*))
		return (cast(ubyte*)t)[0 .. len];
	else
		static assert(false, "YOU CANT DO THAT: type = " ~ T.stringof);
}

void waitabit(){
	int i;
	int waitlimit = 1000000;

	for (i = 0; i < waitlimit; i++) {}
}

ubyte[] mem2hex(ubyte[] dest, ubyte[] src, bool may_fault = false){
	int j = 0;
	for(int i = 0; i < src.length; i++){
		dest[j++] = hexchars[src[i] >> 4];
		dest[j++] = hexchars[src[i] % 16];
	}

	dest[j] = 0;

	return dest[0 .. src.length * 2];
}

ubyte[] hex2mem(ubyte[] dest, ubyte[] src, bool may_fault = false){
	for(int i = 0, j = 0; i < src.length; j++){
		dest[j]  = hexchar2byte(src[i++]);
		dest[j] |= hexchar2byte(src[i++]) << 4;
	}
	
	return dest[0 .. src.length * 2];
}

/***********************************************/
/* WHILE WE FIND NICE HEX CHARS, BUILD A ULONG */
/* RETURN NUMBER OF CHARS PROCESSED 					 */
/***********************************************/
int hex2long(inout ubyte packet[], inout ulong val){
	int numChars = 0;
	byte hexValue; // signed, because -1 is an error code

	val = 0;

	while(packet[numChars] != 0){
		hexValue = hexchar2byte(packet[numChars]);

		if(hexValue >= 0){
			val = (val << 4) | hexValue;
			numChars++;
		}else{
			 break;
		}
	}

	packet = packet[numChars .. $];
	return numChars;
}

// used to go from a real nibble to its hex char
static const char[] hexchars = "1234567890abcdef";

// used to make a hex char into a nibble
byte hexchar2byte(ubyte ch){
	if ((ch >= 'a') && (ch <= 'f')) return (ch-'a'+10);
	if ((ch >= '0') && (ch <= '9')) return (ch-'0');
	if ((ch >= 'A') && (ch <= 'F')) return (ch-'A'+10);
	return (-1);
}

/* this function takes the interrupt id and attempts to
	 translate this number into a unix compatible signal value */
int computeSignal(int exceptionVector)
{
	switch (exceptionVector)
	{
		case idt.Type.DivByZero:		return 8;
		case idt.Type.Debug:			return 5;
		case idt.Type.Breakpoint:		return 5;
		case idt.Type.INTO:				return 16;
		case idt.Type.OutOfBounds:		return 16;
		case idt.Type.InvalidOpcode:  	return 4;
		case idt.Type.NoCoproc:			return 8;
		case idt.Type.DoubleFault:		return 7;
		case idt.Type.CoprocSegOver:	return 11;
		case idt.Type.BadTSS:			return 11;
		case idt.Type.SegNotPresent:	return 11;
		case idt.Type.StackFault:		return 11;
		case idt.Type.GPF:				return 11;
		case idt.Type.PageFault:		return 11;
		case idt.Type.CoprocFault:		return 7;
		default:						return 7;
	}
}

// Converts the current interrupt stack to the format gdb expects
void regs2gdb(idt.interrupt_stack* ir_stack)
{
	tempStack.rax = ir_stack.rax;
	tempStack.rdx = ir_stack.rdx;
	tempStack.rcx = ir_stack.rcx;
	tempStack.rbx = ir_stack.rbx;
	tempStack.rsi = ir_stack.rsi;
	tempStack.rdi = ir_stack.rdi;
	tempStack.rbp = ir_stack.rbp;
	tempStack.rsp = ir_stack.rsp;
	tempStack.r8 = ir_stack.r8;
	tempStack.r9 = ir_stack.r9;
	tempStack.r10 = ir_stack.r10;
	tempStack.r11 = ir_stack.r11;
	tempStack.r12 = ir_stack.r12;
	tempStack.r13 = ir_stack.r13;
	tempStack.r14 = ir_stack.r14;
	tempStack.r15 = ir_stack.r15;
	tempStack.rip = ir_stack.rip;
	tempStack.rflags = ir_stack.rflags;
}

void gdb2regs(idt.interrupt_stack* ir_stack)
{
	ir_stack.rax = tempStack.rax;
	ir_stack.rdx = tempStack.rdx;
	ir_stack.rcx = tempStack.rcx;
	ir_stack.rbx = tempStack.rbx;
	ir_stack.rsi = tempStack.rsi;
	ir_stack.rdi = tempStack.rdi;
	ir_stack.rbp = tempStack.rbp;
	ir_stack.rsp = tempStack.rsp;
	ir_stack.r8 = tempStack.r8;
	ir_stack.r9 = tempStack.r9;
	ir_stack.r10 = tempStack.r10;
	ir_stack.r11 = tempStack.r11;
	ir_stack.r12 = tempStack.r12;
	ir_stack.r13 = tempStack.r13;
	ir_stack.r14 = tempStack.r14;
	ir_stack.r15 = tempStack.r15;
	ir_stack.rip = tempStack.rip;
	ir_stack.rflags = tempStack.rflags;
}
