module libos.libkeyboard;

import user.keycodes;

import libos.console;

class Keyboard {
	static:

	void initialize(ushort* buffer) {

		_writePointer = buffer;
		_readPointer = &(buffer[1]);
		_length = buffer[2];
		_length /= 2; // get # of shorts
		_length -= 3; // account for pointers and length
		_buffer = cast(short[])buffer[3.._length];

		*_readPointer = *_writePointer;
	}

	Key nextKey(out bool released) {
		while (*_readPointer == *_writePointer) {}

		short next = _buffer[*_readPointer];

		released = false;
		if (next < 0) {
			released = true;
			next = -next;
			keyState[next] = false;
		}
		else {
			keyState[next] = true;
		}

		// Read next key at _readPointer
		if (*_readPointer == _length-1) {
			*_readPointer = 0;
		}
		else {
			*_readPointer = *_readPointer + 1;
		}

		return cast(Key)next;
	}

	char translateKey(Key scanCode) {
		// keyboard scancodes are ordered by their position on the keyboard

		// check for shift state
		bool up = false;
		char trans = '\0';

		if (keyState[Key.LeftShift] || keyState[Key.RightShift]) {
			// up key
			up = true;
		}

		if (scanCode >= Key.A && scanCode <= Key.Z) {
			if (up) {
				trans = 'A' + (scanCode - Key.A);
			}
			else {
				trans = 'a' + (scanCode - Key.A);
			}
		}
		else if (scanCode >= Key.Num0 && scanCode <= Key.Num9) {
			if (up) {
				switch (scanCode) {
					case Key.Num0:
						trans = ')';
						break;
					case Key.Num1:
						trans = '!';
						break;
					case Key.Num2:
						trans = '@';
						break;
					case Key.Num3:
						trans = '#';
						break;
					case Key.Num4:
						trans = '$';
						break;
					case Key.Num5:
						trans = '%';
						break;
					case Key.Num6:
						trans = '^';
						break;
					case Key.Num7:
						trans = '&';
						break;
					case Key.Num8:
						trans = '*';
						break;
					default:
					case Key.Num9:
						trans = '(';
						break;
				}
			}
			else {
				trans = '0' + (scanCode - Key.Num0);
			}
		}
		else if (scanCode == Key.Space) {
			trans = ' ';
		}
		else if (scanCode == Key.Tab) {
			trans = '\t';
		}
		else if (scanCode == Key.Quote) {
			if (up) trans = '~'; else trans = '`';
		}
		else if (scanCode == Key.LeftBracket) {
			if (up) trans = '{'; else trans = '[';
		}
		else if (scanCode == Key.RightBracket) {
			if (up) trans = '}'; else trans = ']';
		}
		else if (scanCode == Key.Minus) {
			if (up) trans = '_'; else trans = '-';
		}
		else if (scanCode == Key.Equals) {
			if (up) trans = '+'; else trans = '=';
		}
		else if (scanCode == Key.Comma) {
			if (up) trans = '<'; else trans = ',';
		}
		else if (scanCode == Key.Period) {
			if (up) trans = '>'; else trans = '.';
		}
		else if (scanCode == Key.Semicolon) {
			if (up) trans = ':'; else trans = ';';
		}
		else if (scanCode == Key.Apostrophe) {
			if (up) trans = '"'; else trans = '\'';
		}
		else if (scanCode == Key.Slash) {
			if (up) trans = '?'; else trans = '/';
		}
		else if (scanCode == Key.Backslash) {
			if (up) trans = '|'; else trans = '\\';
		}
		else if (scanCode == Key.Return) {
			trans = '\n';
		}
		else if (scanCode >= Key.Keypad0 && scanCode <= Key.Keypad9) {
			if (!(up)) {
				trans = '0' + (scanCode - Key.Keypad0);
			}
		}
		else if (scanCode == Key.KeypadAsterisk) {
			trans = '*';
		}
		else if (scanCode == Key.KeypadMinus) {
			trans = '-';
		}
		else if (scanCode == Key.KeypadSlash) {
			trans = '/';
		}
		else if (scanCode == Key.KeypadPlus) {
			trans = '+';
		}
		else if (scanCode == Key.KeypadReturn) {
			trans = '\n';
		}
		else if (scanCode == Key.KeypadPeriod) {
			trans = '.';
		}

		return trans;
	}

private:

	static bool keyState[Key.max+1] = false;

	short[] _buffer;
	ushort* _writePointer;
	ushort* _readPointer;
	ushort _length;
}
