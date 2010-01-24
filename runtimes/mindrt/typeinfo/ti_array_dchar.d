/*
 * ti_array_dchar.d
 *
 * This module implements the TypeInfo for dchar[]
 *
 * License: Public Domain
 *
 */

module mindrt.typeinfo.ti_array_dchar;

import mindrt.typeinfo.ti_array_uint;

import mindrt.util;

class TypeInfo_Aw : TypeInfo_Ak {
	char[] toString() {
		return "dchar[]";
	}

	TypeInfo next() {
		return typeid(dchar);
	}
}
