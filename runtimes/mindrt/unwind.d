/*
 * unwind.d
 *
 * This module implements the D runtime unwind functions which serve to
 * process exceptions and backtraces.
 *
 * License: Public Domain
 *
 */

module mindrt.unwind;

import mindrt.common;

extern(C):

void _d_throw(Object obj) {
}

