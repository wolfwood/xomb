/*
 * ti_array_wchar.d
 *
 * This module implements the TypeInfo for wchar[]
 *
 */

module dyndrt.typeinfos.ti_array_wchar;

import dyndrt.typeinfos.ti_array;

class TypeInfo_Au : ArrayInfo!("wchar") { }
