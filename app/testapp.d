/* testapp.d

   Example application to be used with XOmB

*/

module testapp;

import user.syscall;
import user.console;

void main() {
	long foo = add(5,9);

	ConsoleInfo cinfo;
	requestConsole(&cinfo);

	asm {
		mov r15, rax;
	}
	for (;;) {}
}
