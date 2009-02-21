/* XOmB Bare Bones
 *
 * This is the bare minimum needed for an OS written in the D language.
 *
 */

module kernel.core.kmain;

import kernel.dev.console;
import kernel.core.kprintf;

extern(C) void kmain(int flags, void *data) {

	Console.clearScreen();

	kprintfln!("I will eat your {}! {}, {x}")("brains", 10, 3735928559);

	for(;;) {}

}
