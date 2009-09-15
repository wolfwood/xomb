/* kernel.core.log
 *
 * This prints out the pretty log lines when we boot.
 */
module kernel.core.log;

//we can't exactly write to the console
//if we don't import the cosole, now can we?
import kernel.dev.console;

//we need to know about errors to print them out to the screen
import kernel.core.error;

//helps us print to the screen
import kernel.core.kprintf;

// a horizontal rule
const char[] hr = "...........................................................................";

// this function prints a message and an error
// to a log line on the screen.
ErrorVal printToLog(char[] message, ErrorVal e) {

  //call the simpler function to print the message
  printToLog(message);

  //now test the value
  if(e == ErrorVal.Success) {
	  printSuccess();
  } else {
	  printFail();
  }

  return e;
}

//this function does most of the work
//it just prints a string
void printToLog(char[] message) {
	Console.resetColors();
  //there are 14 characters in our print string, so we need
  //to stubtract them from the number of columns and the message
  //length in order to print things out correctly
	kprintf!("  .  {} {} [ ")(message, hr[0..65-message.length]);
	Console.setColors(Color.Yellow, Color.Black);
	kprintf!(".. ")();
	Console.resetColors();
	kprintf!("]")();
}

void printSuccess() {
	int x, y;
	Console.getPosition(x,y);
	Console.setPosition(x-5,y);

	Console.setColors(Color.Green, Color.Black);
	kprintfln!(" OK ")();
}

void printFail() {
	int x, y;
	Console.getPosition(x,y);
	Console.setPosition(x-5,y);

	Console.setColors(Color.Red, Color.Black);
	kprintfln!("FAIL")();
}
