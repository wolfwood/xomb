/*
 * simplyrnd.c
 *
 * This code just writes random stuff to an array.
 *
 */

#include <stdlib.h>
#include <string.h>

#define SIZE 1024*1024
#define ITERATIONS 5000

void perfPoll(int);

void main() {
	srand(0); // OK... not very random, but oh well

	int* array = (int*)malloc(sizeof(int) * SIZE);

	int i,o;
	perfPoll(0);
	for(o = 0; o < ITERATIONS; o++) {
		for(i = 0; i < SIZE; i++) {
			array[i] = (int)rand();
		}
	}
	perfPoll(0);
	for(;;){}
}
