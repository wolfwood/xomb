module xombemu.x86.exception;

enum Exception
{
	Stack,
	GeneralProtection,
	PageFault,
	AlignmentCheck,
}

struct CpuException
{
static:

	void raise(Exception type)
	{

	}

}
