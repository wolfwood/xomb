// interrupts.d -- Abstracted Interrupt Stuff

// This module will select the Interrupt namespace for the currently selected target architecture

module kernel.arch.interrupts;

import kernel.arch.select;

mixin(PublicArchImport!("interrupts"));
