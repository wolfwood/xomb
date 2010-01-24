/* testapp.d

   Example application to be used with XOmB

*/

module testapp;

import user.syscall;
import user.console;
import user.ramfs;

//import libos.console;
import libos.ramfs;

import libos.libdeepmajik.threadscheduler;

void main() {
	log("-- ohai");

	threadYield();

	XombThread* t1 = threadCreate(&thang1);
	XombThread* t2 = threadCreate(&thang2);

	t1.schedule();
	t2.schedule();

	for(ulong i = 0; i < 10; i++){
		dispUlong(i);
		threadYield();
	}

	log("Winnar!");

	//for(;;) {}

}

void thang1(){
	for(ulong i = 100; i < 120; i++){
		dispUlong(i);
		threadYield();
	}
}


void thang2(){
	for(ulong i = 200; i < 230; i++){
		dispUlong(i);
		threadYield();
	}
}