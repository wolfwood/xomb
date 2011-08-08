/*
 * simplyfft.c
 *
 *
 * Code computes fft of an array of complex doubles and mutates
 * in-place this array to give a complex double result.
 *
 * Code is from a module by Dmitry Karasik, and available:
 *   http://cpansearch.perl.org/src/KARASIK/IPA-1.07/Global/fft.c
 *
 */

#include <stdlib.h>
#include <string.h>

#define SWAP(a,b) tempr=(a); (a)=(b); (b)=tempr
#define TWOPI (2*3.14159265358979323846264338327950288419716939937510)
/*---------------------------------------------------------------------------*/
/* Purpose:  This routine replaces DATA by its one-dimensional discrete      */
/*           transform if ISIGN=1 or replaces DATA by its inverse transform  */
/*           if ISIGN=-1.  DATA is a complex array of length NN which is     */
/*           input as a real array of length 2*NN.  No error checking is     */
/*           performed                                                       */
/*                                                                           */
/* Note:     Because this code was adapted from a FORTRAN library, the       */
/*           data array is 1-indexed.  In other words, the first element     */
/*           of the array is assumed to be in data[1].  Because C is zero    */
/*           indexed, the first element of the array is in data[0].  Hence,  */
/*           we must subtract 1 from the data address at the start of this   */
/*           routine so references to data[1] will really access data[0].    */
/*---------------------------------------------------------------------------*/

void perfPoll(int);
double sin(double);

static void fft_1d(double *data, int nn, int isign)
{
	int n, mmax, m, j, istep, i;
	double wtemp, wr, wi, wpr, wpi, theta, tempr, tempi;

	/* Fix indexing problems (see above) */
	data = data - 1;

	/* Bit reversal section */
	n = nn << 1;
	j = 1;
	for (i = 1; i < n; i += 2)
	{
		if (j > i)
		{
			SWAP(data[j], data[i]);
			SWAP(data[j + 1], data[i + 1]);
		}
		m = n >> 1;
		while (m >= 2 && j > m)
		{
			j -= m;
			m = m >> 1;
		}
		j += m;
	}

	/* Danielson-Lanczos section */
	mmax = 2;
	while (n > mmax)
	{
		istep = 2 * mmax;
		theta = TWOPI / (isign * mmax);
		wtemp = sin(0.5 * theta);
		wpr = -2.0 * wtemp * wtemp;
		wpi = sin(theta);
		wr = 1.0;
		wi = 0.0;
		for (m = 1; m < mmax; m += 2)
		{
			for (i = m; i <= n; i += istep)
			{
				j = i + mmax;
				tempr = (double)(wr * data[j] - wi * data[j + 1]);
				tempi = (double)(wr * data[j + 1] + wi * data[j]);
				data[j] = data[i] - tempr;
				data[j + 1] = data[i + 1] - tempi;
				data[i] += tempr;
				data[i + 1] += tempi;
			}
			wtemp = wr;
			wr += wr * wpr - wi * wpi;
			wi += wi * wpr + wtemp * wpi;
		}
		mmax = istep;
	}

	/* Normalizing section */
	if (isign == 1)
	{
		n = nn << 1;
		for (i = 1; i <= n; i++)
			data[i] = data[i] / nn;
	}
}

// Should be a power of two
#define INPUTSIZE (1024*1024)

// some (very literal) sin implementation
// it is not a very good one
double sin(double x) {
	static const double a[] = {
		-0.1666666664,
		 0.008333315,
		-0.0001984090,
		-0.0000027526,
		-0.0000000239
	};
	double xsq = x*x;
	double temp = x*(1
			+ a[0]*xsq
			+ a[1]*xsq*xsq
			+ a[2]*xsq*xsq*xsq
			+ a[3]*xsq*xsq*xsq*xsq
			+ a[4]*xsq*xsq*xsq*xsq*xsq);
	return temp;
}

void main() {
	double* input;
	input = (double*)malloc(sizeof(double) * INPUTSIZE);

	srand(0);
	int i;
	for (i = 0; i < INPUTSIZE; i++) {
		input[i] = (double)rand();
	}

	perfPoll(0);
	for(i = 0; i < 200; i++) {
		fft_1d(input, INPUTSIZE>>1, 1);
	}
	perfPoll(0);
	for(;;) {}
}
