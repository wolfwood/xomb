/*
 * ti_array_ushort.d
 *
 * This module implements the TypeInfo for ushort[]
 *
 * License: Public Domain
 *
 */

module mindrt.typeinfo.ti_array_ushort;

import mindrt.typeinfo.ti_array_short;

import mindrt.util;

class TypeInfo_At : TypeInfo_As {
	char[] toString() { return "ushort[]"; }

	int compare(void *p1, void *p2) {
		ushort[] s1 = *cast(ushort[]*)p1;
		ushort[] s2 = *cast(ushort[]*)p2;
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
		return typeid(ushort);
	}
}
