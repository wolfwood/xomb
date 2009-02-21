// usersyscall.d -- Abstracted Native Syscall Stuff

// This module will select the nativeSyscall function for the currently selected target architecture

module kernel.arch.usersyscall;

import kernel.arch.select;

mixin(PublicArchImport!("usersyscall"));
