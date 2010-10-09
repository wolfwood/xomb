/* xsh.d

   XOmB Native Shell

*/

module hello;

import user.syscall;
import user.ramfs;

import console;

import libos.libdeepmajik.threadscheduler;

void main() {

	Console.initialize();
	Console.backcolor = Color.Black; 
	Console.forecolor = Color.Green;

	Console.putString("\nHello, and Welcome to XOmB\n");
	Console.putString(  "-=-=-=-=-=-=-=-\n\n");

	//for(;;){}

	Console.backcolor = Color.Black; 
	Console.forecolor = Color.LightGray;
}
