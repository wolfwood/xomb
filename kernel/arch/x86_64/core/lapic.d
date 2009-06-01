/*
 * lapic.d
 *
 * This module implements the Local APIC
 *
 */

module kernel.arch.x86_64.core.lapic;

struct LAPIC {
static:
public:

	ErrorVal initialize() {
		return ErrorVal.Success;
	}

private:

}
