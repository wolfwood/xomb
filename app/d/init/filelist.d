module filelist;
import embeddedfs;
void fileList(){
	EmbeddedFS.makeFile!("binaries/hello")();
	EmbeddedFS.makeFile!("binaries/chel")();
	EmbeddedFS.makeFile!("binaries/lspci")();
	EmbeddedFS.makeFile!("binaries/dynhello")();
	EmbeddedFS.makeFile!("binaries/simplymm")();
	EmbeddedFS.makeFile!("binaries/posix")();
	EmbeddedFS.makeFile!("binaries/xsh")();
	EmbeddedFS.makeFile!("data/pci.ids")();
	EmbeddedFS.makeFile!("LICENSE")();
}
