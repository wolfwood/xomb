module nettest;

import console;

import system;

// requied by entry.
import libos.keyboard;
import libos.libdeepmajik.threadscheduler;

// why is this required?
import libos.fs.minfs;

void main(char[][] argv) {
	Console.backcolor = Color.Black;
	Console.forecolor = Color.LightGray;

  char[] name = System.networkDriver.name;
  Console.putString("Driver: ");
	Console.forecolor = Color.Cyan;
  Console.putString(name);
  Console.forecolor = Color.LightGray;
  Console.putString("\n");

  ubyte[6] mac;
  System.networkDriver.initialize();
  System.networkDriver.macAddress(mac);

  Console.putString("   Mac: ");

	Console.backcolor = Color.Black;
	Console.forecolor = Color.Cyan;

  foreach (i, b; mac) {
    if (b < 10) {
      Console.putString("0");
    }
    Console.putInteger(b, 16);
    if (i < 5) {
      Console.forecolor = Color.LightGray;
      Console.putString(":");
      Console.forecolor = Color.Cyan;
    }
  }
  Console.forecolor = Color.LightGray;
  Console.putString("\n");
}
