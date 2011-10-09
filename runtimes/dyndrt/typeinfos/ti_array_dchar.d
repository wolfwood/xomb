/*
 * ti_array_dchar.d
 *
 * This module implements the TypeInfo for dchar[]
 *
 */

module dyndrt.typeinfos.ti_array_dchar;

import dyndrt.typeinfos.ti_array;

class TypeInfo_Aw : ArrayInfo!("dchar") { }
