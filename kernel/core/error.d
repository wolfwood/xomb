/* kerenl.core.error
 *
 * This is the error type that's used by every call
 * that could end up in an error.
 */

module kernel.core.error;

enum ErrorVal {
	Success = 0,
	Fail,
}
