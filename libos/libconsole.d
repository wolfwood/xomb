module libos.libconsole;

import user.syscall;
import user.console;

static ConsoleInfo cinfo;

void initialize() {

	requestConsole(&cinfo);

	if (cinfo.buffer is null) {
		// boo
	}
}
