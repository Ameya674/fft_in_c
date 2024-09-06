#include <stdio.h>
#include <stdlib.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

// Approximate sine using Taylor series
double sine(double x) {
    double term = x, sum = x;
    for (int n = 1; n <= 10; n++) {
        term *= -x * x / (2 * n * (2 * n + 1));
        sum += term;
    }
    return sum;
}

// Approximate cosine using Taylor series
double cosine(double x) {
    double term = 1, sum = 1;
    for (int n = 1; n <= 10; n++) {
        term *= -x * x / (2 * n * (2 * n - 1));
        sum += term;
    }
    return sum;
}

// FFT without libraries
void fft(double *input_real, double *output_real, double *output_imag, int N) {

    if ((N & (N - 1)) != 0) {
        printf("Error: N must be a power of 2.\n");
        return;
    }

    // Allocate arrays for real and imaginary parts
    double *temp_real = (double *)malloc(N * sizeof(double));
    double *temp_imag = (double *)malloc(N * sizeof(double));

    // Initialize real and imaginary arrays
    for (int i = 0; i < N; i++) {
        temp_real[i] = input_real[i];
        temp_imag[i] = 0.0;
    }

    // Bit-reversal permutation
    for (int i = 0, j = 0; i < N; i++) {
        if (i < j) {
            double temp_r = temp_real[i], temp_i = temp_imag[i];
            temp_real[i] = temp_real[j];
            temp_imag[i] = temp_imag[j];
            temp_real[j] = temp_r;
            temp_imag[j] = temp_i;
        }
        for (int k = N >> 1; (j ^= k) < k; k >>= 1);
    }

    // Cooley-Tukey FFT
    for (int step = 2; step <= N; step <<= 1) {
        int m = step >> 1;
        double theta = -2.0 * M_PI / step;
        for (int k = 0; k < N; k += step) {
            for (int j = 0; j < m; j++) {
                double w_real = cosine(j * theta);  // Approximate cosine
                double w_imag = sine(j * theta);    // Approximate sine

                double t_real = w_real * temp_real[k + j + m] - w_imag * temp_imag[k + j + m];
                double t_imag = w_real * temp_imag[k + j + m] + w_imag * temp_real[k + j + m];

                temp_real[k + j + m] = temp_real[k + j] - t_real;
                temp_imag[k + j + m] = temp_imag[k + j] - t_imag;
                temp_real[k + j] += t_real;
                temp_imag[k + j] += t_imag;
            }
        }
    }

    // Store results
    for (int i = 0; i < N; i++) {
        output_real[i] = temp_real[i];
        output_imag[i] = temp_imag[i];
    }

    free(temp_real);
    free(temp_imag);
}

int main() {
    int N = 8; // Example size, must be a power of 2
    double input[] = {5.0, 1.0, 34.0, 3.0, 4.0, 11.0, 6.0, 25.0};
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
