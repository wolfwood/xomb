module embeddedfs;

import mindrt.util;
//import libos.elf.loader;
import libos.fs.minfs;

struct EmbeddedFS{
	static:
	void makeFS(){
		MinFS.format();
		
		// binaries
		xsh = makeFile!("binaries/xsh", true)();
		makeFile!("binaries/hello", true)();
		makeFile!("binaries/chel", true)();
		makeFile!("binaries/fhel", true)();
		
		// data
		makeFile!("kernel/LICENSE", false)();
	}

	ubyte* shellAddr(){
		return xsh.ptr;
	}

private:
	File xsh;

	template makeFile(char[] filename, bool exe){
		File makeFile(){
			const char[] actualFilename = "/" ~ filename;

			// import file
			ubyte[] data = cast(ubyte[])import(filename);

			// create minFS file
			File f =  MinFS.open(actualFilename, AccessMode.Writable);

			// populate
			if(exe){
				memcpy(cast(void*)f.ptr, cast(void*)data.ptr, data.length);
			}else{
				int spacer = ulong.sizeof;

				memcpy(cast(void*)((f.ptr)[spacer..spacer]).ptr,
							 cast(void*)data.ptr, data.length);
			}

			ulong* size = cast(ulong*)f.ptr;

			*size = data.length;

			return f;
		}
	}
}
