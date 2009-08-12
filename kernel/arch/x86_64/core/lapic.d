/*
 * lapic.d
 *
 * This module implements the Local APIC
 *
 */

module kernel.arch.x86_64.core.lapic;

import kernel.arch.x86_64.mutex;

struct LAPIC {
static:
public:

	ErrorVal initialize() {
		return ErrorVal.Success;
	}

private:

	Mutex apLock;

	void startAP(ubyte apicID) {
		apLock.lock();

		// success will be printed by the AP in apExec();
		
		ulong p;
		for (ulong o=0; o < 10000; o++) {
			p = o << 5 + 10;
		}

		sendINIT(apicID);

		for (ulong o = 0; o < 10000; o++) {
			p = o << 5 + 10;
		}

		sendStartup(apicID);

		for (ulong o = 0; o < 10000; o++) {
			p = o << 5 + 10;
		}

		sendStartup(apicID);

		for (ulong o = 0; o < 10000; o++) {
			p = o << 5 + 10;
		}

		// Wait for the AP to boot
		apLock.lock();
		apLock.unlock();
	}
}
