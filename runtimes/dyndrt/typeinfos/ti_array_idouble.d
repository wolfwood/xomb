/*
 * ti_array_idouble.d
 *
 * This module implements the TypeInfo for a idouble[]
 *
 */

module dyndrt.typeinfos.ti_array_idouble;

import dyndrt.typeinfos.ti_array_double;

class TypeInfo_Ap : TypeInfo_Ad {
	char[] toString() {
		return "idouble[]";
	}

	TypeInfo next() {
		return typeid(idouble);
	}
}
