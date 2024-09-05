#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <complex.h>
#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

void fft(double *input, double *output_real, double *output_imag, int N) {
    // Check if N is a power of 2
    if ((N & (N - 1)) != 0) {
        printf("Error: N must be a power of 2.\n");
        return;
    }

    // Allocate memory for the complex array
    double complex *temp = (double complex *)malloc(N * sizeof(double complex));
    if (temp == NULL) {
        printf("Memory allocation failed.\n");
        return;
    }

    // Convert real input to complex format
    for (int i = 0; i < N; i++) {
        temp[i] = input[i] + 0.0 * I;
    }

    // Bit-reversal permutation
    for (int i = 0, j = 0; i < N; i++) {
        if (i < j) {
            double complex t = temp[i];
            temp[i] = temp[j];
            temp[j] = t;
        }
        for (int k = N >> 1; (j ^= k) < k; k >>= 1);
    }

    // Cooley-Tukey FFT algorithm
    for (int step = 2; step <= N; step <<= 1) {
        int m = step >> 1;
        double complex w = cexp(-2.0 * M_PI * I / step);
        for (int k = 0; k < N; k += step) {
            double complex wk = 1.0;
            for (int j = 0; j < m; j++) {
                double complex t = wk * temp[k + j + m];
                temp[k + j + m] = temp[k + j] - t;
                temp[k + j] += t;
                wk *= w;
            }
        }
    }

    // Separate real and imaginary parts
    for (int i = 0; i < N; i++) {
        output_real[i] = creal(temp[i]);
        output_imag[i] = cimag(temp[i]);
    }

    // Free the allocated memory
    free(temp);
}

int main() {
    int N = 8; // Example size, must be a power of 2
    double input[] = {0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0};
    double output_real[N];
    double output_imag[N];

    fft(input, output_real, output_imag, N);

    // Print the result
    printf("Real (Cosine) Component:\n");
    for (int i = 0; i < N; i++) {
        printf("output_real[%d] = %.5f\n", i, output_real[i]);
    }
    
    printf("\nImaginary (Sine) Component:\n");
    for (int i = 0; i < N; i++) {
        printf("output_imag[%d] = %.5f\n", i, output_imag[i]);
    }

    return 0;
}
