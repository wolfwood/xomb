//This should be the return type for all errors

module kernel.error;

enum ErrorVal {
	Success = 0,
	Fail,
	NoSpace,
	BadInputs
}
