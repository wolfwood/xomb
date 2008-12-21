// user.d -- Userland constants

// This module will select the correct module from the currently selected target architecture

module kernel.arch.user;

import kernel.arch.select;

mixin(PublicArchImport!("user"));
