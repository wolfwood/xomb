/*
 * timing.d
 *
 * This module contains the timer and code relevant to reading
 * the current time.
 *
 */

module architecture.timing;

import kernel.core.kprintf;
import kernel.core.error;

struct Timing {
static:

	ErrorVal initialize() {
		return ErrorVal.Success;
	}

	struct Time {
		uint seconds;
		uint minutes;
		uint hours;
	}

	struct Date {
		uint day;
		uint month;
		uint year;
	}

	void currentTime(out Time tm, out Date dt) {
		uint s,m,h;
		uint day,month,year;
		asm {
			LOOP:

			// Get RTC register A
			mov AL, 10;
			out 0x70, AL;
			in AL, 0x71;
			test AL, 0x80;
			// Loop until it is not busy updating
			jne LOOP;

			// Get Seconds
			mov AL, 0x00;
			out 0x70, AL;
			in AL, 0x71;
			mov s, AL;

			// Get Minutes
			mov AL, 0x02;
			out 0x70, AL;
			in AL, 0x71;
			mov m, AL;

			// Get Hours
			mov AL, 0x04;
			out 0x70, AL;
			in AL, 0x71;
			mov h, AL;

			// Get Day of Month (1 to 31)
			mov AL, 0x07;
			out 0x70, AL;
			in AL, 0x71;
			mov day, AL;

			// Get Month (1 to 12)
			mov AL, 0x08;
			out 0x70, AL;
			in AL, 0x71;
			mov month, AL;

			// Get Year (00 to 99)
			mov AL, 0x09;
			out 0x70, AL;
			in AL, 0x71;
			mov year, AL;
		}

		if ((h & 128) == 128) {
			// RTC is reporting 12 hour mode with PM
			h = h & 0b0111_1111;
			h += 12;
		}

		tm.hours = h;
		tm.minutes = m;
		tm.seconds = s;

		dt.day = day;
		dt.month = month;
		// XXX: OMG YEAR 2100 BUG HERE
		dt.year = year + 2000;
	}
}
