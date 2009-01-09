module user.basicio;
//basicio - basic io functions

//Manifest plainness,
//Embrace simplicity,
//        Reduce selfishness,
//        Have few desires.
//                -Lao-tzu, _The Way of Lao-tzu_

import user.syscall;
import std.stdarg;

import libos.console;

import user.keycodes;
import libos.keyboard;

char[256] buffer = "s";

char[] readln()
{
	short key;
	while((key = Keyboard.grabKey()) == Key.Null)
	{

	}

	return buffer;
}

void print(...) {
	if (_arguments.length == 0)
	{
		return;
	}

	char[20] buff;

	foreach(arg; _arguments)
	{
		if (arg == typeid(char[]))
		{
			Console.printString(va_arg!(char[])(_argptr));
		}
		else if (arg == typeid(long))
		{
			long val;
			val = va_arg!(long)(_argptr);

			Console.printString(inttochar(buff, 'd', val));
		}
		else if (arg == typeid(ulong))
		{
			ulong val;
			val = va_arg!(ulong)(_argptr);

			Console.printString(inttochar(buff, 'u', val));
		}
		else if (arg == typeid(int))
		{
			int val;
			val = va_arg!(int)(_argptr);

			Console.printString(inttochar(buff, 'd', val));
		}
		else if (arg == typeid(uint))
		{
			uint val;
			val = va_arg!(int)(_argptr);

			Console.printString(inttochar(buff, 'u', val));
		}
		else if (arg == typeid(short))
		{
			short val;
			val = va_arg!(short)(_argptr);

			Console.printString(inttochar(buff, 'd', val));
		}
		else if (arg == typeid(ushort))
		{
			ushort val;
			val = va_arg!(ushort)(_argptr);

			Console.printString(inttochar(buff, 'u', val));
		}
		else if (arg == typeid(byte))
		{
			byte val;
			val = va_arg!(byte)(_argptr);

			Console.printString(inttochar(buff, 'd', val));
		}
		else if (arg == typeid(ubyte))
		{
			ubyte val;
			val = va_arg!(ubyte)(_argptr);

			Console.printString(inttochar(buff, 'u', val));
		}
		else if (arg == typeid(char))
		{
			char val;
			val = va_arg!(ubyte)(_argptr);

			Console.printChar(val);
		}
		else if (arg == typeid(void*))
		{
		}
	}
}
char[] inttochar(char[] buf, char base, long d)
{
  size_t p = buf.length - 1;
  size_t startIdx = 0;
  ulong ud = d;
  bool negative = false;

  int divisor = 10;

  // If %d is specified and D is minus, put `-' in the head.
  if(base == 'd' && d < 0)
  {
    negative = true;
    ud = -d;
  }
  else if(base == 'x')
    divisor = 16;

  // Divide UD by DIVISOR until UD == 0.
  do
  {
    int remainder = ud % divisor;
    buf[p--] = (remainder < 10) ? remainder + '0' : remainder + 'a' - 10;
  }
  while (ud /= divisor)

    if(negative)
      buf[p--] = '-';

  return buf[p + 1 .. $];
}
