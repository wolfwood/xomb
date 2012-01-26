/* xsh.d

   XOmB Native Shell

*/

module hello;

import console;

// requied by entry.
import libos.keyboard;
import libos.libdeepmajik.threadscheduler;

void main(char[][] argv) {
	Console.backcolor = Color.Black;
	Console.forecolor = Color.Green;

	char[] string = "\nHello, and Welcome to XOmB\n";

	foreach(str; argv){
		string ~= str;
		string ~= "\n";
	}


	string ~= "-=-=-=-=-=-=-=-\n\n";

	Console.backcolor = Color.Black;
	Console.forecolor = Color.LightGray;


	Console.putString(string ~ "\n");


	char[][char[]] dictionary;

	dictionary["foo"] = "bar";
	dictionary["zig"] = "zag";
	dictionary["a"] = "b";
	dictionary["c"] = "d";

	foreach (word; dictionary.keys){
		Console.putString(word ~ " " ~ dictionary[word] ~"\n");
	}
}
