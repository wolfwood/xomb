module kernel.arch.select;

// load the correct files for the cpu abstraction

// just loading x86-64 for now

const char[] architecture = "x86_64";

template PublicArchImport(char[] mod)
{
	const char[] PublicArchImport = `

		public import kernel.arch.` ~ architecture ~ `.` ~ mod ~ `;

	`;
}


