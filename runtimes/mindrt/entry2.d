
import user.ipc;

// Will be linked to the user's main function
int main(char[][]);


// catching the retun code has to happen inside the thread
extern(C) void start3(char[][] argv){
	MessageInAbottle.getMyBottle().exitCode = main(argv);
}
