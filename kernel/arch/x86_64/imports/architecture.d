/*
 * architecture.d
 *
 * This file will publically import all modules used to define
 * the architecture interfaces provided by this architecture.
 *
 */

module architecture;

public import kernel.arch.x86_64.main;
public import kernel.arch.x86_64.cpu;
public import kernel.arch.x86_64.multiprocessor;
public import kernel.arch.x86_64.vm;
public import kernel.arch.x86_64.mutex;
public import kernel.arch.x86_64.pagetable;
