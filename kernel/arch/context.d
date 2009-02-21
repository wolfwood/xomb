// context.d -- For importing the architecture specific context switching code

module kernel.arch.context;

import kernel.arch.select;

mixin(PublicArchImport!("context"));
