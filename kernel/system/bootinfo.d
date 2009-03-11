/*
 * bootinfo.d
 *
 * This module handles the boot loader information.
 *
 */

module kernel.system.bootinfo;

// Import kernel Foo for errors
import kernel.core.error;

// Import all of the acceptable boot loader modules
import Multiboot = kernel.system.multiboot;

// This structure will handle all requests to the information given
// by the boot loader. It makes no assumptions about which boot loader
// is actually used by the system.
struct BootInfo
{
static:
public:

	// All of the types of boot loader specifications in use, so we
	// *can* make assumptions sometimes.
	enum Type
	{
		Multiboot,
	}

	// This function takes in the parameters passed to kmain.
	// It will pass it off to the correct module for utilization.
	ErrorVal initialize(int bootLoaderID, void* data)
	{
		switch(bootLoaderID)
		{
			case 0x2BADB002:

				return Multiboot.verifyBootInformation(bootLoaderID, data);

				break;

			default:

				// This is an unknown boot loader
				return ErrorVal.Fail;

				break;
		}

		return ErrorVal.Success;
	}
}
