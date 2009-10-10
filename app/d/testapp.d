/* testapp.d

   Example application to be used with XOmB

*/

module testapp;

import user.syscall;
import user.console;
import user.ramfs;

import libos.console;
import libos.ramfs;

void main() {

	Console.initialize();
	Console.backcolor = Console.Color.Black; 
	Console.forecolor = Console.Color.Green;
	Console.clear();

	Console.putString("Welcome to XOmB\n\n");

	int fd = Open("/boot/text", 0, 0);

	char[128] str;

	while(read(fd, str, str.length) == str.length){
		Console.putString(str);
	}

	for (;;) {}
}
