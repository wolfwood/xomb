/*
 * unwind.d
 *
 * This module implements the D runtime unwind functions which serve to
 * process exceptions and backtraces.
 *
 */

module dyndrt.unwind;

import dyndrt.common;

extern(C):

void _d_throw(Object obj) {
}

