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

			Console.printString(itoa(buff, 'd', val));
		}
		else if (arg == typeid(ulong))
		{
			ulong val;
			val = va_arg!(ulong)(_argptr);

			Console.printString(itoa(buff, 'u', val));
		}
		else if (arg == typeid(int))
		{
			int val;
			val = va_arg!(int)(_argptr);

			Console.printString(itoa(buff, 'd', val));
		}
		else if (arg == typeid(uint))
		{
			uint val;
			val = va_arg!(int)(_argptr);

			Console.printString(itoa(buff, 'u', val));
		}
		else if (arg == typeid(void*))
		{
		}
	}
}
char[] itoa(char[] buf, char base, long d)
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
