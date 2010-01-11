/*
 * simplymm.c
 *
 *
 * Code computes matrix multiplication of a matrix of ints of some
 * arbitrary size denoted by MATRIX_DIM.
 *
 */

#include <stdlib.h>
#include <string.h>

#define MATRIX_DIM 2048

struct bigint {
	int a;
	int b;
};

void perfPoll(int);

void main() {
	int** Y;
	int** A;
	int** B;

	int i,j,k;

	Y = (int**)malloc(sizeof(int*)*MATRIX_DIM);
	A = (int**)malloc(sizeof(int*)*MATRIX_DIM);
	B = (int**)malloc(sizeof(int*)*MATRIX_DIM);

	for (i=0; i < MATRIX_DIM; i++) {
		Y[i] = (int*)malloc(sizeof(int)*MATRIX_DIM);
		A[i] = (int*)malloc(sizeof(int)*MATRIX_DIM);
		B[i] = (int*)malloc(sizeof(int)*MATRIX_DIM);
	}

	struct bigint bi;
	perfPoll(0);

	for (i=0; i < MATRIX_DIM; i++) {
		for (j=0; j < MATRIX_DIM; j++) {
			for (k=0; k < MATRIX_DIM; k++) {
				Y[i][j] = Y[i][j] + A[i][k] * B[k][j];
			}
		}
	}

	perfPoll(0);
	for(;;){}
}
