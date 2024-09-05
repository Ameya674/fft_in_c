% MATLAB code to perform FFT and separate real and imaginary parts

% Input signal
input = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0];

% Perform FFT
fft_result = fft(input);

% Separate real and imaginary parts
output_real = real(fft_result);
output_imag = imag(fft_result);

% Display the results
fprintf('Real (Cosine) Component:\n');
for i = 1:length(output_real)
    fprintf('output_real[%d] = %.5f\n', i-1, output_real(i));
end

fprintf('\nImaginary (Sine) Component:\n');
for i = 1:length(output_imag)
    fprintf('output_imag[%d] = %.5f\n', i-1, output_imag(i));
end
