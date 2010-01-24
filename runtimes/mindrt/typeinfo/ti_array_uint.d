/*
 * ti_array_uint.d
 *
 * This module implements the TypeInfo for uint[]
 *
 * License: Public Domain
 *
 */

module mindrt.typeinfo.ti_array_uint;

import mindrt.typeinfo.ti_array_int;

import mindrt.util;

class TypeInfo_Ak : TypeInfo_Ai {
	char[] toString() {
		return "uint[]";
	}

	int compare(void *p1, void *p2) {
		uint[] s1 = *cast(uint[]*)p1;
		uint[] s2 = *cast(uint[]*)p2;
		size_t len = s1.length;

		if (s2.length < len) {
			len = s2.length;
		}

		for (size_t u = 0; u < len; u++) {
			int result = s1[u] - s2[u];

			if (result) {
				return result;
			}
		}

		if (s1.length < s2.length) {
			return -1;
		}
		else if (s1.length > s2.length) {
			return 1;
		}

		return 0;
	}

	TypeInfo next() {
		return typeid(uint);
	}
}
