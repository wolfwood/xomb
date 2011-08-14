module libos.video;

struct VideoMode {
	uint width;
	uint height;
}

class VideoDriver {
static:

	// Methods

	VideoMode[] videoModes() {
		return null;
	}

	// Properties

	void videoMode(VideoMode mode) {
		// Lock device and switch mode

		// Set mode
		_mode = mode;

		// Unlock device
	}

	VideoMode videoMode() {
		return _mode;
	}

private:

	VideoMode _mode;
}
