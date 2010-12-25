/* xsh.d

   XOmB Native Shell

*/

module hello;

import user.syscall;

import console;

import user.environment;

import libos.libdeepmajik.threadscheduler;

void main() {
	Console.backcolor = Color.Black; 
	Console.forecolor = Color.Green;

	Console.putString("\nHello, and Welcome to XOmB\n");
	Console.putString(  "-=-=-=-=-=-=-=-\n\n");

	Console.backcolor = Color.Black; 
	Console.forecolor = Color.LightGray;
}
