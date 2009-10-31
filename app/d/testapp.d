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
	Console.backcolor = Color.Black; 
	Console.forecolor = Color.Green;

	Console.putString("\nWelcome to XOmB\n");
	Console.putString("---------------\n\n");

	Console.backcolor = Color.Black; 
	Console.forecolor = Color.Red;

	Console.putString("What to do...\n");

	//char[128] str;

//	while(read(fd, str, str.length) == str.length){
//		Console.putString(str);
//	}

	for(;;) {}

}
