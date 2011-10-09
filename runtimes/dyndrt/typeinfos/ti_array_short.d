/*
 * ti_array_short.d
 *
 * This module implements the TypeInfo for short[]
 *
 */

module dyndrt.typeinfos.ti_array_short;

import dyndrt.typeinfos.ti_array;

class TypeInfo_As : ArrayInfo!("short") { }
