#include <stdio.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <unistd.h>
#include <string.h>

int main(int argc, char** argv){
	char *hello = "hello world\n";

	fprintf(stdout, "%s!\n", hello);

	wconsole(hello, 11);


	printf("Hello wizzerld!\n");

	int fd =  open("/LICENSE", O_RDONLY);

	char foo[11];
	int err;

	do{
		err = read(fd, foo, 10);

		if(err > 0){
			foo[err] = '\0';
			printf(foo);
		}

	}while(err == 10);

	printf("\n");

	int wfd =  open("/out", O_WRONLY|O_CREAT);

	char* moo = "The quick brown w0lfwood jumped over the lazy cl0ckw0rk.\n";

	printf("write to fd %d\n", wfd);
	write(wfd, moo, strlen(moo));

	int i;

	printf("ARGV:\n");

	for(i = 0; i < argc; i++){
		printf("%s ", argv[i]);
	}

	printf("\n");

	printf("/ARGV\n");

	printf("stat size: %d\n", sizeof(struct stat));
	printf("dev_t size: %d\n", sizeof(dev_t));
	printf("ino_t size: %d\n", sizeof(ino_t));
	printf("mode_t size: %d\n", sizeof(mode_t));
	printf("nlink_t size: %d\n", sizeof(nlink_t));
	printf("uid_t size: %d\n", sizeof(uid_t));
	printf("gid_t size: %d\n", sizeof(gid_t));
	printf("off_t size: %d\n", sizeof(off_t));
	printf("time_t size: %d\n", sizeof(time_t));
	return 0;
}
