// vmem.d -- Abstracted VM Stuff

// This module will select the vMem namespace for the currently selected target architecture

module kernel.arch.vmem;

import kernel.arch.select;

mixin(PublicArchImport!("vmem"));
