// syscall.d -- Abstracted Syscall Stuff

// This module will select the Syscall namespace for the currently selected target architecture

module kernel.arch.syscall;

import kernel.arch.select;

mixin(PublicArchImport!("syscall"));
