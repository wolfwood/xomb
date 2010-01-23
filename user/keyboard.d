module user.keyboard;

// Return structures
struct KeyboardInfo {
	short* buffer;
	uint bufferLength;

	int* writePointer;
	int* readPointer;
}
