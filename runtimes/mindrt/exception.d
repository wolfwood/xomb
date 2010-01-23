/*
 * exception.d
 *
 * This module implements the Exception base class.
 *
 */

module mindrt.exception;

// Description: This class represents a recoverable failure.
class Exception : Object {
	char[] msg;

	// Description: Will construct an Exception with the given descriptive message.
	this(char[] msg) {
		this.msg = msg;
	}

	char[] toString() {
		return msg;
	}
}

