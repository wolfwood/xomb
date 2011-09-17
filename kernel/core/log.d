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

import architecture.mutex;

struct Log {
static:
public:

	// a horizontal rule
	const char[] hr = "...........................................................................";

	// this function prints a message and an error
	// to a log line on the screen.
	ErrorVal print(char[] message) {
		//call the simpler function to print the message
		printToLog(message);

		logDepth++;

		return ErrorVal.Success;
	}

	ErrorVal result(ErrorVal e) {
		//now test the value
		logDepth--;
		if(e == ErrorVal.Success) {
			printSuccess();
		} else {
			printFail();
		}

		return e;
	}

private:
	Mutex logLock;

	//this function does most of the work
	//it just prints a string
	void printToLog(char[] message) {
		logLock.lock();
		Console.resetColors();
		//there are 14 characters in our print string, so we need
		//to subtract them from the number of columns and the message
		//length in order to print things out correctly
		uint dots = (logDepth * 2) + 1;
		kprintf!("  {}  {} {} [")(hr[0..dots], message, hr[0..66-message.length-dots]);

		int x, y;

		Console.getPosition(x,y);

		xAtMessage = x;
		yForDepth[logDepth] = Console.getGlobalY();

		Console.setColors(Color.Yellow, Color.Black);
		kprintf!(" .. ")();
		Console.resetColors();
		kprintf!("]\n")();
		logLock.unlock();
	}

	uint logDepth;
	uint xAtMessage;
	long yForDepth[16];

	void printSuccess() {
		printStatus(" OK ", Color.Green, Color.Black);
	}

	void printFail() {
		printStatus("FAIL", Color.Red, Color.Black);
	}

	void printStatus(char[] message, Color fore, Color back) {
		logLock.lock();
		long gY = Console.getGlobalY();
		int x,y;
		int nY;
		Console.getPosition(x,y);
		nY = y - cast(int)(gY - yForDepth[logDepth]);
		if (nY < 0) {
			logLock.unlock();
			return;
		}
		Console.setPosition(xAtMessage,nY);
		Console.setColors(fore, back);
		kprintfln!("{}")(message);
		Console.setPosition(x,y);
		logLock.unlock();
	}
}
