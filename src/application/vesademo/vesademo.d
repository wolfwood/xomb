module application.vesademo;

import user.syscall;
import user.keycodes;

import libos.vesa;
import libos.keyboard;
import libos.console;

// images
ubyte[] xomblogobytes = cast(ubyte[])(import("xomblogo.bin"));		// 400 x 143
ubyte[] xombtextbytes = cast(ubyte[])(import("xombtextlogo.bin"));			// 339 x 63
ubyte[] xkcdbytes = cast(ubyte[])(import("xkcd.bin"));				// 740 x 269

// the radius of the eyeballs
const uint amountOfEvil = 2;

int main()
{
	Keyboard.init();
	Console.init();

	VESA.init();
	bool ret = VESA.pollModes();

	ret = VESA.pollModeInfo();

	short mode = VESA.findBestMode();

	// switch to best mode, enable double buffering
	VESA.ModeInfo mInfo = VESA.switchMode(mode, true);

	//for(;;){}
	//mInfo.workingBuffer = mInfo.videoBuffer + 4096;
	//mInfo.bytesPerScanline = 4096*2;

	// clear screen - white
	clearScreen(mInfo, 0xFFFFFF);

	// draw images
	uint logoY;
	uint logoX;

	// center XOmB logo
	//logoY = (mInfo.yResolution - 143) / 2;
	logoY = 10;
	logoX = (mInfo.xResolution - 400) / 2;

	blitImg(mInfo, logoX, logoY, cast(uint*)&xomblogobytes[0], 400, 143);

	// offset text to just below image
	//logoY += 143 + 20;
	logoY = mInfo.yResolution - 63 - 10;
	logoX = ((mInfo.xResolution - 339) / 2) + 11;

	blitImg(mInfo, logoX, logoY, cast(uint*)&xombtextbytes[0], 339, 63);

	// draw xkcd comic
	// center
	logoY = (mInfo.yResolution - 269) / 2;
	logoX = (mInfo.xResolution - 740) / 2;

	blitImg(mInfo, logoX, logoY, cast(uint*)&xkcdbytes[0], 740, 269);

	// update screen
	VESA.flipBuffer(mInfo);

	// -- DRAW AGAIN -- //

	// clear screen - white
	clearScreen(mInfo, 0xFFFFFF);

	// draw images
	//uint logoY;
	//uint logoX;

	// center XOmB logo
	//logoY = (mInfo.yResolution - 143) / 2;
	logoY = 10;
	logoX = (mInfo.xResolution - 400) / 2;

	blitImg(mInfo, logoX, logoY, cast(uint*)&xomblogobytes[0], 400, 143);

	// offset text to just below image
	//logoY += 143 + 20;
	logoY = mInfo.yResolution - 63 - 10;
	logoX = ((mInfo.xResolution - 339) / 2) + 11;

	blitImg(mInfo, logoX, logoY, cast(uint*)&xombtextbytes[0], 339, 63);

	// draw xkcd comic
	// center
	logoY = (mInfo.yResolution - 269) / 2;
	logoX = (mInfo.xResolution - 740) / 2;

	blitImg(mInfo, logoX, logoY, cast(uint*)&xkcdbytes[0], 740, 269);

	// -- FILL EVIL EYES
	fillRect(mInfo, logoX+276-amountOfEvil, logoY+199-amountOfEvil, logoX+276+amountOfEvil, logoY+199+amountOfEvil, 0xFF0000);
	fillRect(mInfo, logoX+295-amountOfEvil, logoY+199-amountOfEvil, logoX+295+amountOfEvil, logoY+199+amountOfEvil, 0xFF0000);






	// look for CTRL+ALT+DELETE

	short keyCode;
	ushort keyCodeType;

	bool controlDown = false;
	bool delDown = false;
	bool altDown = false;

	while(!(altDown && delDown && controlDown)) {
		keyCode = Keyboard.grabKey();

		if (keyCode != Key.Null)
		{
			if (keyCode < 0)
			{
				keyCodeType = -keyCode;
			}
			else
			{
				keyCodeType = keyCode;
			}

			if (keyCodeType == Key.LeftControl ||
					keyCodeType == Key.RightControl)
			{
				controlDown = (keyCode > 0);
			}

			if (keyCodeType == Key.Delete)
			{
				delDown = (keyCode > 0);
			}

			if (keyCodeType == Key.LeftAlt ||
					keyCodeType == Key.RightAlt)
			{
				altDown = (keyCode > 0);
			}
		}
	}

	// flash evil eyes
	// note: one buffer will have original picture
	//		other buffer will have red eyes

	bool screen = false;

	//clearScreen(mInfo, 0xFF);
	//VESA.flipBuffer(mInfo);

	while(true) {
		VESA.flipBuffer(mInfo);
	}

	for(;;) {}

	return 0;
}

void clearScreen(ref VESA.ModeInfo mInfo, uint clr)
{
	ubyte* workingBufferLineStart = cast(ubyte*)mInfo.workingBuffer;
	uint* workingBufferCurPtr;

	for (uint y=0; y<mInfo.yResolution; y++)
	{
		workingBufferCurPtr = cast(uint*)workingBufferLineStart;
		for (uint x=0; x<mInfo.xResolution; x++)
		{
			(*workingBufferCurPtr) = clr;
			workingBufferCurPtr++;
		}
		workingBufferLineStart += mInfo.bytesPerScanline;
	}
}

void blitImg(ref VESA.ModeInfo mInfo, uint x, uint y, uint* imgBytes, int imgWidth, int imgHeight)
{
	uint* workingBufferCurPtr;
	ubyte* workingBufferLineStart = cast(ubyte*)mInfo.workingBuffer + (mInfo.bytesPerScanline * y);

	for (uint sy=0;sy<imgHeight;sy++)
	{
		workingBufferCurPtr = cast(uint*)(workingBufferLineStart) + x;
		for (uint sx=0;sx<imgWidth;sx++)
		{
			(*workingBufferCurPtr) = (*imgBytes);
			imgBytes++;
			workingBufferCurPtr++;
		}
		workingBufferLineStart += mInfo.bytesPerScanline;
	}
}

void setPixel(ref VESA.ModeInfo mInfo, uint x, uint y, uint clr)
{
	ubyte* ptr;
	ptr = (cast(ubyte*)mInfo.workingBuffer) + (mInfo.bytesPerScanline * y);

	uint* intptr;
	intptr = (cast(uint*)ptr) + x;

	(*intptr) = clr;
}

void setPixelDirect(ref VESA.ModeInfo mInfo, uint x, uint y, uint clr)
{
	ubyte* ptr;
	ptr = (cast(ubyte*)mInfo.videoBuffer) + (mInfo.bytesPerScanline * y);

	uint* intptr;
	intptr = (cast(uint*)ptr) + x;

	(*intptr) = clr;
}

void fillRect(ref VESA.ModeInfo mInfo, uint x, uint y, uint x2, uint y2, uint clr)
{
	// pathetically inefficient:
	for (uint sx = x; sx <= x2; sx++)
	{
		for (uint sy = y; sy <= y2; sy++)
		{
			setPixel(mInfo, sx, sy, clr);
		}
	}
}

void fillRectDirect(ref VESA.ModeInfo mInfo, uint x, uint y, uint x2, uint y2, uint clr)
{
	// also pathetically inefficient:

	for (uint sx = x; sx <= x2; sx++)
	{
		for (uint sy = y; sy <= y2; sy++)
		{
			setPixelDirect(mInfo, sx, sy, clr);
		}
	}
}
