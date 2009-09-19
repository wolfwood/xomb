int nativeSyscall(unsigned int ID, void* ret, void* params);

int add(int a, int b);

struct ConsoleInfo;
void requestConsole(struct ConsoleInfo*);

int allocPage(void* virtualAddress);

void exit(int);
