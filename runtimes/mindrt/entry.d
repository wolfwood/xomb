/*
 * entry.d
 *
 * The entry point to an app.
 *
 */

// Will be linked to the user's main function
int main(char[][]);

extern(C) void _start() {
	// foo

	main(null);

	// exit();
}
