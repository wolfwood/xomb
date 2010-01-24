/*
 * ti_array_ubyte.d
 *
 * This module implements the TypeInfo for a ubyte[]
 *
 * License: Public Domain
 *
 */

module mindrt.typeinfo.ti_array_ubyte;

import mindrt.typeinfo.ti_array_byte;

import mindrt.util;

class TypeInfo_Ah : TypeInfo_Ag {
	char[] toString() { return "ubyte[]"; }

	int compare(void *p1, void *p2) {
		ubyte[] s1 = *cast(ubyte[]*)p1;
		ubyte[] s2 = *cast(ubyte[]*)p2;

		return memcmp(s1.ptr, s2.ptr, s1.length);
	}

	TypeInfo next() {
		return typeid(ubyte);
	}
}
