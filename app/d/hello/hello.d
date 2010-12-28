/* xsh.d

   XOmB Native Shell

*/

module hello;

import user.syscall;

import console;
import libos.keyboard;
import user.environment;

import libos.libdeepmajik.threadscheduler;

void main(char[][] argv) {
	Console.backcolor = Color.Black; 
	Console.forecolor = Color.Green;

	Console.putString("\nHello, and Welcome to XOmB\n");
	Console.putString(  "-=-=-=-=-=-=-=-\n\n");

	Console.backcolor = Color.Black; 
	Console.forecolor = Color.LightGray;

	foreach(str; argv){
		Console.putString(str);
		Console.putString("\n");
	}

	Console.putString("\n");
}
