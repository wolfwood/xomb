// timer.d -- Abstracted High Performance Timer Stuff

// This module will select the Timer namespace for the currently selected target architecture

module kernel.arch.timer;

import kernel.arch.select;

mixin(PublicArchImport!("timer"));
