/*
 * ti_array_bool.d
 *
 * This module implements the TypeInfo for a bool[]
 *
 */

module dyndrt.typeinfos.ti_array_bool;

import dyndrt.typeinfos.ti_array_ubyte;

class TypeInfo_Ab : TypeInfo_Ah {
	char[] toString() {
		return "bool[]";
	}

	TypeInfo next() {
		return typeid(bool);
	}
}
