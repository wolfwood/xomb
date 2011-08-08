/*
 * perfmon.d
 *
 * This module abstracts architectural performance monitor counters.
 *
 */

module architecture.perfmon;

import architecture.cpu;

import kernel.core.error;
import kernel.core.kprintf;

struct PerfMon {
static:
public:

	enum Event {
		L2Evictions,
		L2Misses,
		L2Requests,
		L2ReadRequests,
		L2WriteRequests,
		L2Locks,
	}

	ErrorVal initialize() {
		// Determine capabilites
		ulong ia32_misc_enable = Cpu.readMSR(0x1A0);
		if (!((ia32_misc_enable & 0b10000000) > 0)) {
			return ErrorVal.Fail;
		}

		return ErrorVal.Success;
	}

	bool hasCapability(Event evt) {
		if (evt < Event.max) {
			return true;
		}
		return false;
	}

	uint eventCount() {
		return 4;
	}

	ErrorVal registerEvent(uint idx, Event evt) {
		if (idx >= eventCount()) {
			return ErrorVal.Fail;
		}

		if (!hasCapability(evt)) {
			return ErrorVal.Fail;
		}

		uint mask = 0;

		switch (evt) {
			case Event.L2Evictions:
				mask = L2_LINES_OUT;
				break;
			case Event.L2Misses:
				mask = L2_LINES_IN;
				break;
			case Event.L2Requests:
				mask = L2_RQSTS;
				break;
			case Event.L2ReadRequests:
				mask = L2_LD;
				break;
			case Event.L2WriteRequests:
				mask = L2_ST;
				break;
			case Event.L2Locks:
				mask = L2_LOCK;
				break;
			default:
				break;
		}

		registerMSR(idx, mask);

		return ErrorVal.Success;
	}

	ulong pollEvent(uint idx) {
		if (idx >= eventCount()) {
			return ErrorVal.Fail;
		}

		return pollMSR(idx);
	}

private:
	static const uint IA32_PMC_BASE = 0xc1;
	static const uint IA32_PERFEVTSEL_BASE = 0x186;

	static const uint OS_FLAG = 1 << 17;
	static const uint USR_FLAG = 1 << 16;
	static const uint ALL_CORES_FLAG = 0b11 << 14;
	static const uint UNI_CORE_FLAG = 1 << 14;
	static const uint ENABLE_FLAG = 1 << 22;

	static const uint MESI_ALL = 0b1111 << 8;

	void registerMSR(uint idx, uint mask) {
		mask |= OS_FLAG;
		mask |= USR_FLAG;
		mask |= ALL_CORES_FLAG;
		mask |= ENABLE_FLAG;
		mask |= MESI_ALL;
		Cpu.writeMSR(IA32_PERFEVTSEL_BASE + idx, mask);
	}

	ulong pollMSR(uint idx) {
		return Cpu.readMSR(IA32_PMC_BASE + idx);
	}

	// MSRs

	// IA32_PERFEVTSEL0 186H if CPUID.0AH:EAX[15:8] > 0
	// IA32_PERFEVTSEL1 187H
	// IA32_PERFEVTSEL2 188H
	// IA32_PERFEVTSEL3 189H

	// IA32_PMC0 0C1H
	// IA32_PMC1 0C2H
	// IA32_PMC2 0C3H
	// IA32_PMC3 0C4H

	// PERFEVTSELX (* - generally important)
	// 31:24	: CMASK - a value that when it isn't zero, the counter is only
	//			: incremented when the detected condition is greater than or equal
	//			: to this value
	// 23		: Invert flag - used with CMASK, makes CMASK operate as less than
	// 22		: * Enable Counters - 1=counting is enabled
	// 20		: INT (APIC int enable) - 1=processor will generate
	//			: local APIC exception on counter overflow
	// 19		: PC (pin control)
	// 18		: Edge Detect
	// 17		: * OS (os mode) - 1=condition is counted when in Ring 0
	// 16		: * USR (usermode) - 1=condition is counted only when in Ring 3
	// 15:14	: * 11 - all cores, 01 - this core
	// 13		: agent specificity?!?
	// 13:12	: hardware prefetch qualification
	// 11:8		: MESI qualification
	// 7:0		: * Event select (use the events listed below)

	// Other MSRs

	// IA32_PERF_STATUS 198H - Current perf state value
	// IA32_PERF_CTL	199H - Target perf state value

	// IA32_MISC_ENABLE 1A0H - bit 7 - perf monitoring available (ReadOnly, 1=yes)

	// Events:

	static const uint L2_LINES_OUT = 0x26;
	static const uint L2_LINES_IN = 0x24;
	static const uint L2_M_LINES_OUT = 0x27;
	static const uint L2_M_LINES_IN = 0x25;
	static const uint L2_IFETCH = 0x28;
	static const uint L2_LD = 0x29;
	static const uint L2_ST = 0x2a;
	static const uint L2_LOCK = 0x2b;
	static const uint L2_RQSTS = 0x2e;

	// L2_LINES_OUT (26H) - counts the # of L2 cache lines evicted
	// L2_M_LINES_OUT (27H) - counts the # of modified (written back) L2 cache lines
	// L2_IFETCH (28H) - counts the # of instruction cache line reqs from the IFU
	// L2_LD (29H) - L2 cache read reqs
	// L2_ST (2AH) - L2 cache store reqs (L1 miss, and L2 data req)
	// L2_LOCK (2BH) - L2 cache lock (L1 miss)
	// L2_RQSTS (2EH) - all completed L2 cache reqs
}
