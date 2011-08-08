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

#include "cycle.h"

#define MATRIX_DIM 2048

struct bigint {
	int a;
	int b;
};

void main() {

	ticks header_t0, header_t1, read_t0, read_t1, compute_t0, compute_t1, write_t0, write_t1;

	header_t0 = getticks();

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

	header_t1 = getticks();

	compute_t0 = getticks();
	struct bigint bi;
	for (i=0; i < MATRIX_DIM; i++) {
		for (j=0; j < MATRIX_DIM; j++) {
			for (k=0; k < MATRIX_DIM; k++) {
				Y[i][j] = Y[i][j] + A[i][k] * B[k][j];
			}
		}
	}
	compute_t1 = getticks();

	read_t1 = read_t0 = 0;
	write_t1 = write_t0 = 0;

	printf("Header Elapsed : %f\n", elapsed(header_t1, header_t0));
	printf("Read Elapsed : %f\n", elapsed(read_t1, read_t0));
	printf("Compute Elapsed : %f\n", elapsed(compute_t1, compute_t0));
	printf("Write Elapsed : %f\n", elapsed(write_t1, write_t0));
}
