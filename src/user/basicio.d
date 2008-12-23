module user.basicio;
//basicio - basic io functions

//Manifest plainness,
//Embrace simplicity,
//        Reduce selfishness,
//        Have few desires.
//                -Lao-tzu, _The Way of Lao-tzu_

import user.syscall;

void print(char [] fmt, ...) {
  for (int i = 0; i < _arguments.length; i++){
    if (_arguments[i] == typeid(int))
    {
      int j = *cast(int *)_argptr;
      char[6] buff;
      echo(inttochar(buff, 'd', cast(ulong)j));
    }
    if (_arguments[i] == typeid(long))
    {
      echo("long");
      long j = *cast(long *)_argptr;
      echo("lol");
      char[1000] buff;
      echo(inttochar(buff, 'd', j));
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
