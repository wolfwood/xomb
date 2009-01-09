// VESA driver for XOmB

module kernel.dev.vesa;

import kernel.arch.vmem;

import kernel.core.error;
import kernel.core.log;

import kernel.dev.vga;

struct VESA
{
static:

	void* int10Func;

	ubyte[vMem.PAGE_SIZE] biosIVT;

	void init()
	{

		// need to keep the first page, it gets overwritten by the AP trampoline code
		biosIVT[0..vMem.PAGE_SIZE] = (cast(ubyte*)vMem.VM_BASE_ADDR)[0..vMem.PAGE_SIZE];

		// the location of the int 10h handler pointer in the realmode IVT
		ushort* int10Handler_loc = cast(ushort*)(&biosIVT[(0x04 * 0x10)]);

		// the int 10h function pointer
		// do real-mode translation
		// (segment << 4) + offset
		// segment = int10Handler_loc[1]
		// offset = int10Handler_loc[0]
		void* int10Handler = cast(void*)((int10Handler_loc[1] << 4) + int10Handler_loc[0]);

		int10Func = int10Handler;
		int10Handler += vMem.VM_BASE_ADDR;
		//int10Handler = cast(void*)(vMem.VM_BASE_ADDR + 0xc0000 + 0x12b);

		ubyte* int10Func = cast(ubyte*)int10Handler;
		//kprintfln!("IVT: {} [{x}:{x}] @ {}")(int10Handler_loc, int10Handler_loc[1], int10Handler_loc[0], int10Handler);

		//kprintf!("bytes: ")();
		//for(int i =0; i<10; i++)
		{
			//kprintf!("{x} ")(int10Func[i]);
		}
		//kprintfln!("")();
	}

	// This function will restore the first page, used by the AP startup code
	// This region of code contains the BIOS IVT.
	void restoreIVT()
	{
		(cast(ubyte*)vMem.VM_BASE_ADDR)[0..vMem.PAGE_SIZE] = biosIVT[0..vMem.PAGE_SIZE];
		//kprintfln!("IVT: {x}")((cast(ushort*)(&biosIVT[0x4 * 0x10]))[0]);
	}

	ErrorVal validate()
	{
		ubyte vesaInfo[256];
		void* vesaPtr = vMem.translateAddress( &vesaInfo[0] );
		asm{
			"movq $0x4f00, %%rax";
			"movq %0, %%rdi" :: "o" vesaPtr : "rdi";
			"int $0x10";
		}

		return ErrorVal.Success;
	}

private:

}
