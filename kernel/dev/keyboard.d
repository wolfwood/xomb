module kernel.dev.keyboard;

// Import the architecture specific keyboard driver
import architecture.keyboard;

import kernel.core.error;

import kernel.config;

import user.keycodes;

import kernel.dev.console;

import kernel.filesystem.ramfs;
import kernel.mem.giballocator;
import kernel.mem.gib;

class Keyboard {
static:

	ErrorVal initialize() {
		_buffer = RamFS.create("/devices/keyboard", Access.Kernel | Access.Read | Access.Write);
		ErrorVal ret = KeyboardImplementation.initialize(&putKey);
		return ret;
	}

private:

	void putKey(Key nextKey, bool released) {
		keyState[nextKey] = !released;

		char translated = translateScancode(nextKey);
		if (translated != '\0' && !released) {
			// printable
			Console.putCharUnsafe(translated);
		}

		if (released) {
			nextKey = -nextKey;
		}
	}

	static bool keyState[256] = false;
	Gib _buffer;

	char translateScancode(Key scanCode) {
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
			if (up) trans = '_'; else trans = '.';
		}
		else if (scanCode == Key.Semicolon) {
			if (up) trans = ':'; else trans = ';';
		}
		else if (scanCode == Key.Apostrophe) {
			if (up) trans = '"'; else trans = '\'';
		}
		else if (scanCode == Key.Slash) {
			if (up) trans = '|'; else trans = '\\';
		}
		else if (scanCode == Key.Backslash) {
			if (up) trans = '?'; else trans = '/';
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
		else if (scanCode == Key.KeypadBackslash) {
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

}
