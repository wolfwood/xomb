/*
 * ti_array_byte.d
 *
 * This module implements the TypeInfo for a byte[]
 *
 * License: Public Domain
 *
 */

module mindrt.typeinfo.ti_array_byte;

import mindrt.util;

class TypeInfo_Ag : TypeInfo {
	char[] toString() {
		return "byte[]";
	}

	hash_t getHash(void *p) {
		byte[] s = *cast(byte[]*)p;
		size_t len = s.length;
		byte *str = s.ptr;
		hash_t hash = 0;

		while (1) {
			switch (len) {
				case 0:
					return hash;

				case 1:
					hash *= 9;
					hash += *cast(ubyte *)str;
					return hash;

				case 2:
					hash *= 9;
					hash += *cast(ushort *)str;
					return hash;

				case 3:
					hash *= 9;
					hash += (*cast(ushort *)str << 8) +
						(cast(ubyte *)str)[2];
					return hash;

				default:
					hash *= 9;
					hash += *cast(uint *)str;
					str += 4;
					len -= 4;
					break;
			}
		}

		return hash;
	}

	int equals(void *p1, void *p2) {
		ubyte[] s1 = *cast(ubyte[]*)p1;
		ubyte[] s2 = *cast(ubyte[]*)p2;

		return s1.length == s2.length &&
			memcmp(s1.ptr, s2.ptr, s1.length) == 0;
	}

	int compare(void *p1, void *p2) {
		byte[] s1 = *cast(byte[]*)p1;
		byte[] s2 = *cast(byte[]*)p2;
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

	size_t tsize() {
		return (byte[]).sizeof;
	}

	uint flags() {
		return 1;
	}

	TypeInfo next() {
		return typeid(byte);
	}
}
