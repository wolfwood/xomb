module embeddedfs;

import util;
import libos.elf.loader;
import libos.elf.elf;
import libos.fs.minfs;

import filelist;

struct EmbeddedFS{
	static:
	void makeFS(){
		MinFS.format();

		// binaries + data files
		fileList();

		// symlinks
		MinFS.link("/binaries/posix", "/binaries/cat");
		MinFS.link("/binaries/posix", "/binaries/cp");
		MinFS.link("/binaries/posix", "/binaries/echo");
		MinFS.link("/binaries/posix", "/binaries/ls");
		MinFS.link("/binaries/posix", "/binaries/ln");

		// ensure init knows what to run next
		xsh = MinFS.open("/binaries/xsh", AccessMode.Writable|AccessMode.AllocOnAccess|AccessMode.User|AccessMode.Executable);
	}

	ubyte[] shell(){
		return xsh;
	}

	template makeFile(char[] filename, bool autodetect = true, bool iself = true){
		File makeFile(){
			const char[] actualFilename = "/" ~ filename;

			// import file
			ubyte[] data = cast(ubyte[])import(filename);

			// create minFS file
			File f;
			bool elf;
			AccessMode accessmode = AccessMode.Writable|AccessMode.AllocOnAccess|AccessMode.User;

			// figure out if its an elf binary
			static if(autodetect){
				elf = Elf.isValid(data.ptr);
			}else{
				elf = iself;
			}

			if(elf){
				accessmode |= AccessMode.Executable;
			}

			f =  MinFS.open(actualFilename, accessmode, true);

			// populate
			if(elf){
				Loader.load(data, f);
			}else{
				int spacer = ulong.sizeof;

				memcpy(cast(void*)((f.ptr)[spacer..spacer]).ptr,
							 cast(void*)data.ptr, data.length);

				ulong* size = cast(ulong*)f.ptr;

				*size = data.length;
			}

			return f;
		}
	}

private:
	File xsh;
}
