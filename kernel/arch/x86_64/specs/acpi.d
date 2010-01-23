/*
 * acpi.d
 *
 * This module provides an interface to ACPI
 *
 */

module kernel.arch.x86_64.specs.acpi;

// XXX : A small hack to make our code look neat and tidy
//     : Forward Reference our imports.
private import kernel.arch.x86_64.specs.acpitables;

struct ACPI
{
static:
public:

	// ACPI.Tables
	import kernel.arch.x86_64.specs.acpitables;
}
