/*
 * ti_array_long.d
 *
 * This module implements the TypeInfo for long[]
 *
 */

module dyndrt.typeinfos.ti_array_long;

import dyndrt.typeinfos.ti_array;

class TypeInfo_Al : ArrayInfo!("long") { }
