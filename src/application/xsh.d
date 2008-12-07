module application.xsh;

import user.syscall;

int main() {
	
	//when will I ever grow up?
	char mander, meleon;
	char [1] izard;

	echo("xsh: XOmB shell\n");


	//d doesn't like my beautiful lne of code. Asshole.
	//while(mander = grabch()) {
	meleon = grabch();
	while(true) {
		if(meleon != '\0' ){
			izard[0] = meleon;
			echo(izard);
			if(mander == '\n') {
				echo("\n$>\n");
			}
		}
		// you cannot quit the shell! bwa ha ha ha ha
		meleon = grabch();
	}	
	//gotta get the keyboard system call running...
	exit(0);

	//d is awesome
	return 0;
}

