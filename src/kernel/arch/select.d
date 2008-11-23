module kernel.arch.select;

// load the correct files for the cpu abstraction

// just loading x86-64 for now




// Abstraction

// CPU
public import kernel.arch.x86_64.init;

// IDT
public import kernel.arch.x86_64.idt;

// SYSCALL
public import syscall = kernel.arch.x86_64.syscall;

// LOCKS
public import kernel.arch.locks;

// VMEM
public import kernel.arch.x86_64.vmem;

// TIMER
public import kernel.arch.x86_64.hpet;


// try and get rid of the dependencies on these:

