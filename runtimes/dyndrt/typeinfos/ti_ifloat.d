/*
 * ti_ifloat.d
 *
 * This module implements the TypeInfo for the ifloat type.
 *
 */

module dyndrt.typeinfos.ti_ifloat;

import dyndrt.typeinfos.ti_float;

class TypeInfo_o : TypeInfo_f {
    char[] toString() {
		return "ifloat";
	}
}
