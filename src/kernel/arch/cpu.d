// cpu.d -- Architecture "Cpu" selector

// This module will select the Cpu namespace for the currently selected target architecture

module kernel.arch.cpu;

import kernel.arch.select;

mixin(PublicArchImport!("cpu"));
