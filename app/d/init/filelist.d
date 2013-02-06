module filelist;
import embeddedfs;
void fileList(){
	EmbeddedFS.makeFile!("data/pci.ids")();
	EmbeddedFS.makeFile!("binaries/chel")();
	EmbeddedFS.makeFile!("binaries/lspci")();
	EmbeddedFS.makeFile!("binaries/nettest")();
	EmbeddedFS.makeFile!("binaries/xsh")();
	EmbeddedFS.makeFile!("binaries/hello")();
	EmbeddedFS.makeFile!("binaries/posix")();
	EmbeddedFS.makeFile!("LICENSE")();
}
