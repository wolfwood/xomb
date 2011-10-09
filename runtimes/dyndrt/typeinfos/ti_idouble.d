/*
 * ti_idouble.d
 *
 * This module implements the TypeInfo for the idouble type.
 *
 */

module dyndrt.typeinfos.ti_idouble;

import dyndrt.typeinfos.ti_double;

class TypeInfo_p : TypeInfo_d {
    char[] toString() {
		return "idouble";
	}
}
