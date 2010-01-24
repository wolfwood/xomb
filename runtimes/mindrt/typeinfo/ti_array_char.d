/*
 * ti_array_char.d
 *
 * This module implements the TypeInfo for a char[]
 *
 * License: Public Domain
 *
 */

module mindrt.typeinfo.ti_array_char;

import mindrt.typeinfo.ti_array_byte;

class TypeInfo_Aa : TypeInfo_Ag {
	char[] toString() {
		return "char[]";
	}

	hash_t getHash(void *p) {
		char[] s = *cast(char[]*)p;
		hash_t hash = 0;

		version (all) {
			foreach (char c; s) {
				hash = hash * 11 + c;
			}
		}
		else {
			size_t len = s.length;
			char *str = s;

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
		}
		return hash;
	}

	TypeInfo next() {
		return typeid(char);
	}
}
