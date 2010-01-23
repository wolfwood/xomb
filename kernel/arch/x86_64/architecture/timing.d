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

struct Time {
	uint seconds;
	uint minutes;
	uint hours;

	void opSubAssign(Time b) {
		ulong total = inSeconds();
		ulong total_b = b.inSeconds();
		total -= total_b;

		seconds = total % 60;
		total /= 60;
		minutes = total % 60;
		total /= 60;
		hours = cast(uint)total;
	}

	ulong inSeconds() {
		return cast(ulong)seconds + (cast(ulong)minutes * 60L) + (cast(ulong)hours * 60L * 60L);
	}
}

struct Date {
	uint day;
	uint month;
	uint year;
}

struct Timing {
static:

	ErrorVal initialize() {
		return ErrorVal.Success;
	}

	void sleep(uint seconds) {
		Time curTime;
		currentTime(curTime);

		Time newTime;
		for(;;) {
			currentTime(newTime);
			// get difference
			newTime -= curTime;

			if (newTime.inSeconds >= seconds) {
				return;
			}
		}
	}

	void currentDate(out Date dt) {
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

		dt.day = day;
		dt.month = month;
		dt.year = year;

		// Convert from BCD to decimal
		dt.day = (((dt.day & 0xf0) >> 4) * 10) + (dt.day & 0xf);
		dt.month = (((dt.month & 0xf0) >> 4) * 10) + (dt.month & 0xf);
		dt.year = (((dt.year & 0xf0) >> 4) * 10) + (dt.year & 0xf);
		// XXX: OMG YEAR 2100 BUG HERE
		dt.year = dt.year + 2000;
	}

	void currentTime(out Time tm) {
		uint s,m,h;
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
		}

		if ((h & 128) == 128) {
			// RTC is reporting 12 hour mode with PM
			h = h & 0b0111_1111;
			h += 12;
		}

		tm.hours = h;
		tm.minutes = m;
		tm.seconds = s;

		// Convert from BCD to decimal
		tm.hours = (((tm.hours & 0xf0) >> 4) * 10) + (tm.hours & 0xf);
		tm.minutes = (((tm.minutes & 0xf0) >> 4) * 10) + (tm.minutes & 0xf);
		tm.seconds = (((tm.seconds & 0xf0) >> 4) * 10) + (tm.seconds & 0xf);
	}
}
