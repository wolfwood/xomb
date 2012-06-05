module filelist;
import embeddedfs;
void fileList(){
	EmbeddedFS.makeFile!("binaries/xsh")();
	EmbeddedFS.makeFile!("binaries/nm")();
	EmbeddedFS.makeFile!("binaries/hello")();
	EmbeddedFS.makeFile!("binaries/dynhello")();
	EmbeddedFS.makeFile!("binaries/chel")();
	EmbeddedFS.makeFile!("binaries/lspci")();
//	EmbeddedFS.makeFile!("binaries/simplymm")();
	EmbeddedFS.makeFile!("binaries/posix")();
//	EmbeddedFS.makeFile!("binaries/gcc")();
	EmbeddedFS.makeFile!("binaries/strings")();
	EmbeddedFS.makeFile!("LICENSE")();
}
