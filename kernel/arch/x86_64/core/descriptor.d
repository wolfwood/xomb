module kernel.arch.x86_64.core.descriptor;

	// This list provides the types allowed for a system segment descriptor
	enum SystemSegmentType {
		LocalDescriptorTable	= 0b0010,
		AvailableTSS			= 0b1001,
		BusyTSS					= 0b1011,
		CallGate				= 0b1100,
		InterruptGate			= 0b1110,
		TrapGate				= 0b1111
	}


