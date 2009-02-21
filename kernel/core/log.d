module kernel.log;


import kernel.dev.vga;

const char[] spaces = "...........................................................................";

void printLogLine(char[] string)
{
	Console.resetColors();
	kprintf!("  .  {} {} [ ")(string, spaces[0..65-string.length]);
	Console.setColors(Color.Yellow, Color.Black);
	kprintf!(".. ")();
	Console.resetColors();
	kprintf!("]")();
}

void printLogSuccess()
{
	int x,y;
	Console.getPosition(x,y);
	Console.setPosition(x-5,y);
	Console.setColors(Color.HighGreen, Color.Black);
	kprintfln!(" OK ")();
}

void printLogFail()
{
	int x,y;
	Console.getPosition(x,y);
	Console.setPosition(x-5,y);
	Console.setColors(Color.HighRed, Color.Black);
	kprintfln!("FAIL")();
}
