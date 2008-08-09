module kernel.arch.select;

// load the correct files for the cpu abstraction

// just loading x86-64 for now




// Abstraction

// CPU
public import kernel.arch.x86_64.init;

// SYSCALL
public import syscall = kernel.arch.x86_64.syscall;

// LOCKS
public import locks = kernel.arch.x86_64.locks;





// try and get rid of the dependencies on these:

