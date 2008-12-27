module application.xsh;

import user.syscall;
import user.malloc;
import user.basicio;
import user.keycodes;

import libos.keyboard;

int main() {

	//when will I ever grow up?
	char meleon;
	char [1] izard;
	char [256] line_buff;
	int buff_pos;
	void *x;

	// init the keyboard libOS
	Keyboard.init();

	echo("xsh: XOmB shell\n\n$>");


	//d doesn't like my beautiful lne of code. Asshole.
	//while(mander = grabch()) {
	while(true) {
		meleon = Keyboard.grabChar();

		if(meleon != '\0' ){
      buff_pos++;
      line_buff[buff_pos] = meleon;
			izard[0] = meleon;
			echo(izard);
			if(meleon == '\n') {
        buff_pos++;
        line_buff[buff_pos] = '\0';
        buff_pos = 0;
				echo("$>");
			}
      if(meleon == 'm') {
        x = malloc(1000);
        echo("$>");
      }
      if(meleon == 'f') {
        free(x);
        echo("$>");
      }
		}
	}
	exit(0);

	//d is awesome
	return 0;
}


