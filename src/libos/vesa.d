module libos.vesa;

import user.syscall;
import x86emu = user.xombemu.x86emu;

import user.basicio;

struct VESA
{
static:

	struct ModeInfoBlock
	{
		// Mandatory information for all VBE revisions
		ushort ModeAttributes;
		ubyte  WinAAttributes;
		ubyte  WinBAttributes;
		ushort WinGranularity;
		ushort WinSize;
		ushort WinASegment;
		ushort WinBSegment;
		uint WinFuncPtr;
		ushort BytesPerScanLine;
		// Mandatory information for VBE 1.2 and above
		ushort XResolution;
		ushort YResolution;
		ubyte  XCharSize;
		ubyte  YCharSize;
		ubyte  NumberOfPlanes;
		ubyte  BitsPerPixel;
		ubyte  NumberOfBanks;
		ubyte  MemoryModel;
		ubyte  BankSize;
		ubyte  NumberOfImagePages;
		ubyte  Reserved_page;
		// Direct Color fields (required for direct/6 and YUV/7 memory models)
		ubyte  RedMaskSize;
		ubyte  RedFieldPosition;
		ubyte  GreenMaskSize;
		ubyte  GreenFieldPosition;
		ubyte  BlueMaskSize;
		ubyte  BlueFieldPosition;
		ubyte  RsvdMaskSize;
		ubyte  RsvdFieldPosition;
		ubyte  DirectColorModeInfo;
		// Mandatory information for VBE 2.0 and above
		uint PhysBasePtr;
		uint OffScreenMemOffset;
		ushort OffScreenMemSize;
		// Mandatory information for VBE 3.0 and above
		ushort LinBytesPerScanLine;
		ubyte  BnkNumberOfPages;
		ubyte  LinNumberOfPages;
		ubyte  LinRedMaskSize;
		ubyte  LinRedFieldPosition;
		ubyte  LinGreenMaskSize;
		ubyte  LinGreenFieldPosition;
		ubyte  LinBlueMaskSize;
		ubyte  LinBlueFieldPosition;
		ubyte  LinRsvdMaskSize;
		ubyte  LinRsvdFieldPosition;
		uint MaxPixelClock;
		ubyte  Reserved[189];
	}

	// The official VBE Information Block
	struct VbeInfoBlock
	{
		ubyte[4]  VbeSignature;
		ushort VbeVersion;
		ushort OemStringPtr_Off;
		ushort OemStringPtr_Seg;
		ubyte[4]  Capabilities;
		ushort VideoModePtr_Off;
		ushort VideoModePtr_Seg;
		ushort TotalMemory;
		ushort OemSoftwareRev;
		ushort OemVendorNamePtr_Off;
		ushort OemVendorNamePtr_Seg;
		ushort OemProductNamePtr_Off;
		ushort OemProductNamePtr_Seg;
		ushort OemProductRevPtr_Off;
		ushort OemProductRevPtr_Seg;
		ushort[111]  Reserved; // used for dynamicly generated mode list
		ubyte[256]  OemData;
	}

	// XOmB's internal ModeInfo structure
	struct ModeInfo
	{
		// The resolution of the display
		int xResolution;
		int yResolution;

		// The bits per pixel
		int bitsPerPixel;

		// This is a pointer to the video buffer (a physical address)
		// It will need to be mapped into device space by the kernel
		// This can be changed through the driver for double buffering
		void* videoBuffer;
		ulong bufferLength;

		// This is the working buffer
		void* workingBuffer;

		// The number of bytes that represents each scanline
		int bytesPerScanline;

		// bytesPerScanline for one screen
		int bytesPerScreenScanline;
	}

	// contains information about the device's VBE capabilities
	bool vInfoBlockLoaded = false;
	VbeInfoBlock vInfoBlock;

	// contains information about available modes
	uint modeCount = 0;
	const uint MAX_MODES = 35;
	ModeInfoBlock[MAX_MODES] modeInfo;
	ushort[MAX_MODES] modeNumber;

	// Contains information passed by the initVESA syscall
	VESAInfo vInfo;

	// initializes the emulator and gets kernel support
	void init()
	{
		x86emu.init();

		vInfo = initVESA();

		x86emu.mapRam(vInfo.biosRegion);

		vInfoBlockLoaded = false;
		modeCount = 0;
	}

	// executes BIOS code to find the supported modes
	bool pollModes()
	{
		VbeInfoBlock* infoBlock = cast(VbeInfoBlock*)(vInfo.biosRegion + 0xf0000);

		// We want VBE 2.0 information
		infoBlock.VbeSignature[0] = cast(ubyte)('V');
		infoBlock.VbeSignature[1] = cast(ubyte)('B');
		infoBlock.VbeSignature[2] = cast(ubyte)('E');
		infoBlock.VbeSignature[3] = cast(ubyte)('2');

		// reset the registers
		x86emu.clearRegisters();

		// Map the stack to 0xFFFFF
		x86emu.mapStack(0xf000, 0xffff);

		// ES:DI is the output for the routine
		x86emu.setReg(x86emu.Register.ES, 0xf000);
		x86emu.setReg(x86emu.Register.DI, 0x0000);

		// select routine 4f00h
		x86emu.setReg(x86emu.Register.AX, 0x4f00);

		// fire int 10h
		x86emu.fireInterrupt(0x10);

		print("xombemu: done\n");

		// success?
		// look for 0x004f in the AX register
		ulong val;
		x86emu.getRegU(x86emu.Register.AX,val);
		if ((val & 0xffff) != 0x4f)
		{
			print("VESA poll modes (4f00h) failed\n");
			return false;
		}

		print("VESA poll modes (4f00) passed\n");

		// read off list
		// it is located at 0xF0000 of mapped ram
		// which is biosRegion + 0xf0000
		print(cast(ulong)infoBlock, "\n");

		// mode list is located at the SEG:OFF in the list in ram
		ushort* modeList = cast(ushort*)(vInfo.biosRegion + (infoBlock.VideoModePtr_Seg << 4) + infoBlock.VideoModePtr_Off);

		print(infoBlock.VideoModePtr_Seg, ":", infoBlock.VideoModePtr_Off, " <-- modelist\n");

		print("supported modes: [");
		bool first=true;
		while(*modeList != 0xffff)
		{
			if (modeCount < MAX_MODES)
			{
				modeNumber[modeCount] = *modeList;
				modeCount++;
			}

			if (first)
			{ print(*modeList); first = false; }
			else
			{ print(", ", *modeList); }
			modeList++;
		}

		print("]\npollModes done\n");

		// copy the structure
		vInfoBlock = *infoBlock;
		vInfoBlockLoaded = true;

		// return success
		return true;
	}

	// requests information for all supported modes through
	// the emulation layer and routine 4f01h
	bool pollModeInfo()
	{
		for (int i = 0; i < modeCount; i++)
		{
			// request information about the mode
			// (force the Linear Frame Buffer by or'ing 0x4000)
			ModeInfoBlock* mInfo = requestModeInformation(0x4000 | modeNumber[i]);

			if (mInfo is null)
			{
				// mode info not present, unsuccessful emulation
				modeInfo[i] = ModeInfoBlock.init;
			}
			else
			{
				modeInfo[i] = *mInfo;

				print("Mode ", modeNumber[i], ": ", modeInfo[i].XResolution, "x", modeInfo[i].YResolution, " ", modeInfo[i].BitsPerPixel, "bpp\n");
			}
		}

		// success
		return true;
	}

	// this function will request information about a particular mode
	ModeInfoBlock* requestModeInformation(short mode)
	{
		x86emu.clearRegisters();

		// stack is at 0xfffff;
		x86emu.mapStack(0xf000, 0xffff);

		// ES:DI is the output for the routine
		x86emu.setReg(x86emu.Register.ES, 0xf000);
		x86emu.setReg(x86emu.Register.DI, 0x0000);

		// CX is the mode number
		x86emu.setReg(x86emu.Register.CX, mode);

		// select routine 4f01h
		x86emu.setReg(x86emu.Register.AX, 0x4f01);

		// fire int 10h
		x86emu.fireInterrupt(0x10);

		// success?
		// look for 0x4f in the AX register
		ulong val;
		x86emu.getRegU(x86emu.Register.AX,val);
		if ((val & 0xffff) != 0x4f)
		{
			print("VESA poll mode info (4f01h) failed\n");
			return null;
		}

		return cast(ModeInfoBlock*)(vInfo.biosRegion + 0xf0000);
	}

	// This function will return the compatible mode or -1 if one cannot be found.
	short findCompatibleMode(ushort xResolution, ushort yResolution, ushort bitsPerPixel)
	{
		for (int i = 0; i < modeCount; i++)
		{
			if (modeInfo[i].XResolution == xResolution &&
				modeInfo[i].YResolution == yResolution &&
				modeInfo[i].BitsPerPixel == bitsPerPixel)
			{
				// mode info matches what was requested
				return modeNumber[i];
			}
		}

		// could not find a suitable mode
		return -1;
	}

	// will find the biggest baddest mode available
	short findBestMode()
	{
		short mode = -1;
		for (int i = 0; i < modeCount; i++)
		{
			// this comparison biases X-Resolution, therefore biasing widescreens
			// the best 32bpp will most likely be selected
			if (mode == -1 || (modeInfo[i].XResolution > modeInfo[mode].XResolution ||
								modeInfo[i].BitsPerPixel >= modeInfo[mode].BitsPerPixel))
			{
				// this mode is better than the last mode
				mode = i;
			}
		}

		// return the best mode
		print("best mode: (", modeNumber[mode], ")", modeInfo[mode].XResolution, "x", modeInfo[mode].YResolution, " ", modeInfo[mode].BitsPerPixel, "bpp\n");
		print("mode's physptr: ", modeInfo[mode].PhysBasePtr, "\n");
		print("mode's buffer len: ", (modeInfo[mode].YResolution * modeInfo[mode].LinBytesPerScanLine), "\n");
		return modeNumber[mode];
	}

	// This function will switch the video mode, clear the video buffer, and give it to the user.
	// you can even use modes that were deemed unsupported in the pollModes()
	// you can even use future modes that are not VESA standardized as well
	ModeInfo switchMode(short mode, bool doubleBuffer)
	{
		x86emu.clearRegisters();

		// mInfo - what we will return
		ModeInfo mInfo;

		// this points to a filled mode info structure
		// returned by the VBE 4f01h routine
		ModeInfoBlock* mInfoBlk;

		int i;

		for (i = 0; i < modeCount; i++)
		{
			if (modeNumber[i] == mode)
			{
				// found the mode
				mInfoBlk = &modeInfo[i];
				break;
			}
		}
		if (i == modeCount)
		{
			// mode not available

			mInfoBlk = requestModeInformation(mode);

			if (mInfoBlk is null)
			{
				// no mode information found
				// this is dramatically bad
				print("VESA set mode (4f02h) failed: no information about the mode can be found\n");
				return ModeInfo.init;
			}
		}

		mInfo.xResolution = mInfoBlk.XResolution;
		mInfo.yResolution = mInfoBlk.YResolution;

		mInfo.bitsPerPixel = mInfoBlk.BitsPerPixel;

		mInfo.bytesPerScanline = mInfoBlk.LinBytesPerScanLine;

		// allocate the device
		ulong bufferLen;
		bufferLen = mInfoBlk.LinBytesPerScanLine * mInfoBlk.YResolution;

		// this is the buffer length of a single buffer, so set it now
		mInfo.bufferLength = bufferLen;

		if (doubleBuffer)
		{
			bufferLen *= 2;
		}

		// map in the video memory to the environment
		mInfo.videoBuffer = mapDevice(cast(void*)(mInfoBlk.PhysBasePtr), bufferLen);

		// stack is at 0xfffff;
		x86emu.mapStack(0xf000, 0xffff);

		// ES:DI is the output for the routine
		x86emu.setReg(x86emu.Register.ES, 0xf000);
		x86emu.setReg(x86emu.Register.DI, 0x0000);

		// BX is the mode number to set
		// We want a linear frame buffer, so we OR by 0x4000
		x86emu.setReg(x86emu.Register.BX, 0x4000 | mode);

		// select routine 4f02h
		x86emu.setReg(x86emu.Register.AX, 0x4f02);

		// fire int 10h
		x86emu.fireInterrupt(0x10);

		// success?
		// look for 0x4f in the AX register
		ulong val;
		x86emu.getRegU(x86emu.Register.AX,val);
		if ((val & 0xffff) != 0x4f)
		{
			print("VESA set mode (4f02h) failed with error: ", val >> 8, "\n");
			curMode = ModeInfo.init;
			return ModeInfo.init;
		}

		// note: probably won't print anything, haha
		print("VESA set mode (4f02h) succeeded\n");

		if (doubleBuffer)
		{
			allocScreens(2, mInfo);
		}
		else
		{
			mInfo.workingBuffer = mInfo.videoBuffer;
			mInfo.bytesPerScreenScanline = mInfo.bytesPerScanline;
		}

		// copy the information for the user
		curMode = mInfo;

		return mInfo;
	}

	int curScreen = 0;
	ModeInfo curMode;

	bool allocScreens(int numberScreens, ref ModeInfo mInfo)
	{
		// increases the buffer size for double buffering.
		x86emu.clearRegisters();

		// stack is at 0xfffff;
		x86emu.mapStack(0xf000, 0xffff);

		// select routine 4f01h
		x86emu.setReg(x86emu.Register.AX, 0x4f06);

		// select subroutine 0000h
		// (Set Scanline Length in Pixels)
		x86emu.setReg(x86emu.Register.BX, 0x0000);

		// set CX to the desired width
		x86emu.setReg(x86emu.Register.CX, mInfo.xResolution * numberScreens);

		// fire int 10h
		x86emu.fireInterrupt(0x10);

		// success?
		// look for 0x4f in the AX register
		ulong val;
		x86emu.getRegU(x86emu.Register.AX,val);
		if ((val & 0xffff) != 0x4f)
		{
			print("VESA set display start (4f07h) failed\n");
			return false;
		}

		curScreen = 0;
		x86emu.getRegU(x86emu.Register.BX, val);
		mInfo.bytesPerScreenScanline = mInfo.bytesPerScanline;
		mInfo.bytesPerScanline = val;

		// depending on the bpp
		mInfo.workingBuffer = mInfo.videoBuffer + mInfo.bytesPerScreenScanline;

		return true;
	}

	bool flipBuffer(ref ModeInfo mInfo)
	{
		x86emu.clearRegisters();

		// stack is at 0xfffff;
		x86emu.mapStack(0xf000, 0xffff);

		// select routine 4f01h
		x86emu.setReg(x86emu.Register.AX, 0x4f07);

		// select subroutine 0000h
		// (Set Display Start)
		x86emu.setReg(x86emu.Register.BX, 0x0000);

		// set CX to the X position within the buffer
		if (curScreen == 0)
		{
			x86emu.setReg(x86emu.Register.CX, curMode.xResolution);
			curScreen = 1;
		}
		else
		{
			x86emu.setReg(x86emu.Register.CX, 0);
			curScreen = 0;
		}

		// set DX to the Y position within the buffer
		x86emu.setReg(x86emu.Register.DX, 0);

		// fire int 10h
		x86emu.fireInterrupt(0x10);

		// success?
		// look for 0x4f in the AX register
		ulong val;
		x86emu.getRegU(x86emu.Register.AX,val);
		if ((val & 0xffff) != 0x4f)
		{
			print("VESA set display start (4f07h) failed\n");
			return false;
		}

		// do the working buffer first
		mInfo.workingBuffer = mInfo.videoBuffer;
		if (curScreen == 0)
		{
			// the video buffer is ahead of the working buffer
			mInfo.videoBuffer -= mInfo.bytesPerScreenScanline;
		}
		else
		{
			// the video buffer is behind the working buffer
			mInfo.videoBuffer += mInfo.bytesPerScreenScanline;
		}

		return true;
	}
}

