module console;

public import user.console;
import SysConsole = libos.console;

alias char[] string;

struct Point {
	uint x;
	uint y;
}

class Console {
static:

	void initialize(ubyte* vidmem) {
		SysConsole.Console.initialize(vidmem);
	}

	void resetColor() {
		SysConsole.Console.resetColor();
	}

	void forecolor(Color clr) {
		SysConsole.Console.forecolor = clr;
	}

	Color forecolor() {
		return SysConsole.Console.forecolor();
	}

	void backcolor(Color clr) {
		SysConsole.Console.backcolor = clr;
	}

	Color backcolor() {
		return SysConsole.Console.backcolor();
	}

	void putString(string foo) {
		return SysConsole.Console.putString(foo);
	}

	void putChar(char foo) {
		return SysConsole.Console.putChar(foo);
	}

  void putInteger(long num, uint base = 10) {
    putString(itoa(num, base));
  }

	uint width() {
		return SysConsole.Console.width();
	}

	uint height() {
		return SysConsole.Console.height();
	}

	void reset() {
		resetColor();
		clear();
	}

	void clear() {
		SysConsole.Console.clear();
	}

	Point position() {
		Point ret;
		SysConsole.Console.getPosition(ret.x, ret.y);
		return ret;
	}

	void position(uint x, uint y) {
		SysConsole.Console.setPosition(x,y);
	}

	void scroll(uint numLines) {
		SysConsole.Console.scroll(numLines);
	}
}

private:
  string itoa(long val, uint base = 10) {
    int intlen;
    long tmp = val;

    bool negative;

    if (tmp < 0) {
      negative = true;
      tmp = -tmp;
      intlen = 2;
    }
    else {
      negative = false;
      intlen = 1;
    }

    while (tmp >= base) {
      tmp /= base;
      intlen++;
    }

    //allocate

    string ret = new char[intlen];

    intlen--;

    if (negative) {
      tmp = -val;
    } else {
      tmp = val;
    }

    do {
      uint off = cast(uint)(tmp % base);
      char replace;
      if (off < 10) {
        replace = cast(char)('0' + off);
      }
      else if (off < 36) {
        off -= 10;
        replace = cast(char)('a' + off);
      }
      ret[intlen] = replace;
      tmp /= base;
      intlen--;
    } while (tmp != 0);

    if (negative) {
      ret[intlen] = '-';
    }

    return ret;
  }

  string utoa(ulong val, uint base = 10) {
    int intlen;
    ulong tmp = val;

    intlen = 1;

    while (tmp >= base) {
      tmp /= base;
      intlen++;
    }

    //allocate
    tmp = val;

    string ret = new char[intlen];

    intlen--;

    do {
      uint off = cast(uint)(tmp % base);
      char replace;
      if (off < 10) {
        replace = cast(char)('0' + off);
      }
      else if (off < 36) {
        off -= 10;
        replace = cast(char)('a' + off);
      }
      ret[intlen] = replace;
      tmp /= base;
      intlen--;
    } while (tmp != 0);

    return ret;
  }

private union intFloat {
  int l;
  float f;
}

private union longDouble {
  long l;
  double f;
}

private union longReal {
  struct inner {
    short exp;
    long frac;
  }

  inner l;
  real f;
}

string ctoa(cfloat val, uint base = 10) {
  if (val is cfloat.infinity) {
    return "inf";
  }
  else if (val.re !<>= 0.0 && val.im !<>= 0.0) {
    return "nan";
  }

  return ftoa(val.re, base) ~ " + " ~ ftoa(val.im, base) ~ "i";
}

string ctoa(cdouble val, uint base = 10) {
  if (val is cdouble.infinity) {
    return "inf";
  }
  else if (val.re !<>= 0.0 && val.im !<>= 0.0) {
    return "nan";
  }

  return dtoa(val.re, base) ~ " + " ~ ftoa(val.im, base) ~ "i";
}

string ctoa(creal val, uint base = 10) {
  if (val is creal.infinity) {
    return "inf";
  }
  else if (val is creal.nan) {
    return "nan";
  }

  return rtoa(val.re, base) ~ " + " ~ ftoa(val.im, base) ~ "i";
}

string ftoa(float val, uint base = 10) {
  if (val == float.infinity) {
    return "inf";
  }
  else if (val !<>= 0.0) {
    return "nan";
  }
  else if (val == 0.0) {
    return "0";
  }

  long mantissa;
  long intPart;
  long fracPart;

  short exp;

  intFloat iF;
  iF.f = val;

  // Conform to the IEEE standard
  exp = ((iF.l >> 23) & 0xff) - 127;
  mantissa = (iF.l & 0x7fffff) | 0x800000;
  fracPart = 0;
  intPart = 0;

  if (exp >= 31) {
    return "0";
  }
  else if (exp < -23) {
    return "0";
  }
  else if (exp >= 23) {
    intPart = mantissa << (exp - 23);
  }
  else if (exp >= 0) {
    intPart = mantissa >> (23 - exp);
    fracPart = (mantissa << (exp + 1)) & 0xffffff;
  }
  else { // exp < 0
    fracPart = (mantissa & 0xffffff) >> (-(exp + 1));
  }

  string ret;
  if (iF.l < 0) {
    ret = "-";
  }

  ret ~= itoa(intPart, base);
  ret ~= ".";
  for (uint k; k < 7; k++) {
    fracPart *= 10;
    ret ~= cast(char)((fracPart >> 24) + '0');
    fracPart &= 0xffffff;
  }

  // round last digit
  bool roundUp = (ret[$-1] >= '5');
  ret = ret[0..$-1];

  while (roundUp) {
    if (ret.length == 0) {
      return "0";
    }
    else if (ret[$-1] == '.' || ret[$-1] == '9') {
      ret = ret[0..$-1];
      continue;
    }
    ret[$-1]++;
    break;
  }

  // get rid of useless zeroes (and point if necessary)
  foreach_reverse(uint i, chr; ret) {
    if (chr != '0' && chr != '.') {
      ret = ret[0..i+1];
      break;
    }
    else if (chr == '.') {
      ret = ret[0..i];
      break;
    }
  }

  return ret;
}

string dtoa(double val, uint base = 10, bool doIntPart = true) {
  if (val is double.infinity) {
    return "inf";
  }
  else if (val !<>= 0.0) {
    return "nan";
  }
  else if (val == 0.0) {
    return "0";
  }

  long mantissa;
  long intPart;
  long fracPart;

  long exp;

  longDouble iF;
  iF.f = val;

  // Conform to the IEEE standard
  exp = ((iF.l >> 52) & 0x7ff);
  if (exp == 0) {
    return "0";
  }
  else if (exp == 0x7ff) {
    return "inf";
  }
  exp -= 1023;

  mantissa = (iF.l & 0xfffffffffffff) | 0x10000000000000;
  fracPart = 0;
  intPart = 0;

  if (exp < -52) {
    return "0";
  }
  else if (exp >= 52) {
    intPart = mantissa << (exp - 52);
  }
  else if (exp >= 0) {
    intPart = mantissa >> (52 - exp);
    fracPart = (mantissa << (exp + 1)) & 0x1fffffffffffff;
  }
  else { // exp < 0
    fracPart = (mantissa & 0x1fffffffffffff) >> (-(exp + 1));
  }

  string ret;
  if (iF.l < 0) {
    ret = "-";
  }

  if (doIntPart) {
    ret ~= itoa(intPart, base);
    ret ~= ".";
  }

  for (uint k; k < 7; k++) {
    fracPart *= 10;
    ret ~= cast(char)((fracPart >> 53) + '0');
    fracPart &= 0x1fffffffffffff;
  }

  // round last digit
  bool roundUp = (ret[$-1] >= '5');
  ret = ret[0..$-1];

  while (roundUp) {
    if (ret.length == 0) {
      return "0";
    }
    else if (ret[$-1] == '.' || ret[$-1] == '9') {
      ret = ret[0..$-1];
      continue;
    }
    ret[$-1]++;
    break;
  }

  // get rid of useless zeroes (and point if necessary)
  foreach_reverse(uint i, chr; ret) {
    if (chr != '0' && chr != '.') {
      ret = ret[0..i+1];
      break;
    }
    else if (chr == '.') {
      ret = ret[0..i];
      break;
    }
  }

  return ret;
}

string rtoa(real val, uint base = 10) {
  static if (real.sizeof == 10) {
    // Support for 80-bit extended precision

    if (val is real.infinity) {
      return "inf";
    }
    else if (val !<>= 0.0) {
      return "nan";
    }
    else if (val == 0.0) {
      return "0";
    }

    long mantissa;
    long intPart;
    long fracPart;

    long exp;

    longReal iF;
    iF.f = val;

    // Conform to the IEEE standard
    exp = iF.l.exp & 0x7fff;
    if (exp == 0) {
      return "0";
    }
    else if (exp == 32767) {
      return "inf";
    }
    exp -= 16383;

    mantissa = iF.l.frac;
    fracPart = 0;
    intPart = 0;

    if (exp >= 31) {
      return "0";
    }
    else if (exp < -64) {
      return "0";
    }
    else if (exp >= 64) {
      intPart = mantissa << (exp - 64);
    }
    else if (exp >= 0) {
      intPart = mantissa >> (64 - exp);
      fracPart = mantissa << (exp + 1);
    }
    else { // exp < 0
      fracPart = mantissa >> (-(exp + 1));
    }

    string ret;
    if (iF.l.exp < 0) {
      ret = "-";
    }

    ret ~= itoa(intPart, base);
    ret ~= ".";
    for (uint k; k < 7; k++) {
      fracPart *= 10;
      ret ~= cast(char)((fracPart >> 64) + '0');
    }

    // round last digit
    bool roundUp = (ret[$-1] >= '5');
    ret = ret[0..$-1];

    while (roundUp) {
      if (ret.length == 0) {
        return "0";
      }
      else if (ret[$-1] == '.' || ret[$-1] == '9') {
        ret = ret[0..$-1];
        continue;
      }
      ret[$-1]++;
      break;
    }

    // get rid of useless zeroes (and point if necessary)
    foreach_reverse(uint i, chr; ret) {
      if (chr != '0' && chr != '.') {
        ret = ret[0..i+1];
        break;
      }
      else if (chr == '.') {
        ret = ret[0..i];
        break;
      }
    }

    return ret;
  }
  else {
    return ftoa(cast(double)val, base);
  }
}
