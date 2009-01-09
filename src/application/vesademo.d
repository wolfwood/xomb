module application.vesademo;

import user.syscall;

import libos.vesa;
import libos.keyboard;
import libos.console;

// hehe
import user.xomblogo;		// 400 x 143
import user.xombtextlogo;	// 339 x 63

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

	// clear screen - white
	clearScreen(mInfo, 0xFFFFFF);

	// draw images
	uint logoY;
	uint logoX;

	// center XOmB logo
	logoY = (mInfo.yResolution - 143) / 2;
	logoX = (mInfo.xResolution - 400) / 2;

	blitImg(mInfo, logoX, logoY, cast(uint*)&xomblogobytes[0], 400, 143);

	// offset text to just below image
	logoY += 143 + 20;
	logoX = ((mInfo.xResolution - 339) / 2) + 11;

	blitImg(mInfo, logoX, logoY, cast(uint*)&xombtextbytes[0], 339, 63);

	// update screen
	VESA.flipBuffer(mInfo);

	for(;;) {}

	return 0;
}

void clearScreen(ref VESA.ModeInfo mInfo, uint clr)
{
	uint* workingBufferLineStart = cast(uint*)mInfo.workingBuffer;
	uint* workingBufferCurPtr;

	for (uint y=0; y<mInfo.yResolution; y++)
	{
		workingBufferCurPtr = workingBufferLineStart;
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

	uint* workingBufferLineStart = cast(uint*)mInfo.workingBuffer + (mInfo.bytesPerScanline * y);
	for (uint sy=0;sy<imgHeight;sy++)
	{
		workingBufferCurPtr = workingBufferLineStart + x;
		for (uint sx=0;sx<imgWidth;sx++)
		{
			(*workingBufferCurPtr) = (*imgBytes);
			imgBytes++;
			workingBufferCurPtr++;
		}
		workingBufferLineStart += mInfo.bytesPerScanline;
	}
}
