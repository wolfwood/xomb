/*
 * ti_array_wchar.d
 *
 * This module implements the TypeInfo for wchar[]
 *
 * License: Public Domain
 *
 */

module mindrt.typeinfo.ti_array_wchar;

import mindrt.typeinfo.ti_array_ushort;

import mindrt.util;

class TypeInfo_Au : TypeInfo_At {
	char[] toString() {
		return "wchar[]";
	}

	TypeInfo next() {
		return typeid(wchar);
	}
}
