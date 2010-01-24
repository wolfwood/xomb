/*
 * ti_array_ulong.d
 *
 * This module implements the TypeInfo for ulong[]
 *
 * License: Public Domain
 *
 */

module mindrt.typeinfo.ti_array_ulong;

import mindrt.typeinfo.ti_array_long;

import mindrt.util;

class TypeInfo_Am : TypeInfo_Al {
	char[] toString() {
		return "ulong[]";
	}

	int compare(void *p1, void *p2) {
		ulong[] s1 = *cast(ulong[]*)p1;
		ulong[] s2 = *cast(ulong[]*)p2;
		size_t len = s1.length;

		if (s2.length < len) {
			len = s2.length;
		}

		for (size_t u = 0; u < len; u++) {
			if (s1[u] < s2[u]) {
				return -1;
			}
			else if (s1[u] > s2[u]) {
				return 1;
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
		return typeid(ulong);
	}
}
