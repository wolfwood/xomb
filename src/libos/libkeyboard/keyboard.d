module libos.libkeyboard.keyboard;

import user.keycodes;
import Syscall = user.syscall;

struct Keyboard
{

static:

	void init()
	{
		kInfo = Syscall.initKeyboard();
	}

	short grabKey()
	{
		short ret = bufferGrabKey();

		short key = ret;

		bool up;

		if (ret < 0)
		{
			up = true;
			ret = -ret;
		}

		if (ret >= Key.max)
		{
			return Key.Null;
		}

		keyState[ret] = !up;

		if (ret == Key.LeftShift || ret == Key.RightShift)
		{
			shiftState = keyState[Key.LeftShift] | keyState[Key.RightShift];
		}
		else if (ret == Key.LeftControl || ret == Key.RightControl)
		{
			ctrlState = keyState[Key.LeftControl] | keyState[Key.RightControl];
		}
		else if (ret == Key.LeftAlt || ret == Key.RightAlt)
		{
			altState = keyState[Key.LeftAlt] | keyState[Key.RightAlt];
		}

		return key;
	}

	char translateCode(short code)
	{
		if (code <= 0) { return '\0'; }

		// these translations only work on positive values
		// therefore, all up states must be ignored

		char ret;
		if (shiftState)
		{
			ret = translateShift[code];
		}
		else
		{
			ret = translate[code];
		}

		if (ret != '\xFF')
		{
			return ret;
		}

		return '\0';
	}

	// block until a printable character is detected
	char grabChar()
	{
		short key;
		char ret;

		for(;;)
		{
			key = grabKey();

			ret = translateCode(key);

			if (ret != '\xFF')
			{
				return ret;
			}
		}

		return 0;
	}



private:

	Syscall.KeyboardInfo kInfo;

	// keeps track of specfic states
	bool shiftState;
	bool altState;
	bool ctrlState;

	// keeps track of the key state
	// true: the key is pressed
	bool keyState[Key.max];

	char translate[Key.max] = [
		Key.A: 'a', Key.B: 'b', Key.C: 'c', Key.D: 'd', Key.E: 'e', Key.F: 'f',
		Key.G: 'g', Key.H: 'h', Key.I: 'i', Key.J: 'j', Key.K: 'k', Key.L: 'l',
		Key.M: 'm', Key.N: 'n', Key.O: 'o', Key.P: 'p', Key.Q: 'q', Key.R: 'r',
		Key.S: 's', Key.T: 't', Key.U: 'u', Key.V: 'v', Key.W: 'w', Key.X: 'x',
		Key.Y: 'y', Key.Z: 'z',

		Key.Num0: '0', Key.Num1: '1', Key.Num2: '2', Key.Num3: '3', Key.Num4: '4',
		Key.Num5: '5', Key.Num6: '6', Key.Num7: '7', Key.Num8: '8', Key.Num9: '9',

		Key.Period: '.', Key.Comma: ',', Key.Slash: '\\', Key.Backslash: '/',
		Key.Semicolon: ';', Key.LeftBracket: '[', Key.RightBracket: ']',
		Key.Minus: '-', Key.Equals: '=', Key.Quote: '`', Key.Apostrophe: '\'',

		Key.Return: '\n', Key.Space: ' ',
	];

	char translateShift[Key.max] = [
		Key.A: 'A', Key.B: 'B', Key.C: 'C', Key.D: 'D', Key.E: 'E', Key.F: 'F',
		Key.G: 'G', Key.H: 'H', Key.I: 'I', Key.J: 'J', Key.K: 'K', Key.L: 'L',
		Key.M: 'M', Key.N: 'N', Key.O: 'O', Key.P: 'P', Key.Q: 'Q', Key.R: 'R',
		Key.S: 'S', Key.T: 'T', Key.U: 'U', Key.V: 'V', Key.W: 'W', Key.X: 'X',
		Key.Y: 'Y', Key.Z: 'Z',

		Key.Num0: ')', Key.Num1: '!', Key.Num2: '@', Key.Num3: '#', Key.Num4: '$',
		Key.Num5: '%', Key.Num6: '^', Key.Num7: '&', Key.Num8: '*', Key.Num9: '(',

		Key.Period: '>', Key.Comma: '<', Key.Slash: '|', Key.Backslash: '?',
		Key.Semicolon: ':', Key.LeftBracket: '{', Key.RightBracket: '}',
		Key.Minus: '_', Key.Equals: '+', Key.Quote: '~', Key.Apostrophe: '"',

		Key.Return: '\n', Key.Space: ' ',
	];

	short bufferGrabKey()
	{
		if ((*kInfo.writePointer) != (*kInfo.readPointer) &&
			((*kInfo.readPointer) < (kInfo.bufferLength)))
		{
			return kInfo.buffer[(*kInfo.readPointer)++];
		}
		else
		{
			return kInfo.buffer[kInfo.bufferLength - 1];
		}

		return 0;
	}
}
