% Original sine wave
n = (0:50)';
x = sin(2*pi*0.05*n);

% Apply Hamming window
w = hamming(length(x));
x_windowed = x .* w;

w_test = hamming(8);

x_fft = (fft(x_windowed));

figure(1)
plot(w_test);

figure(2)

subplot(2,2,1)
plot(n, x)
title('Before Hamming')
ylabel('Amplitude')
ylim([-1.1 1.1])
grid on

subplot(2,2,2)
plot(n, x_windowed)
title('After Hamming')
xlabel('Sample number')
ylabel('Amplitude')
ylim([-1.1 1.1])
grid on

subplot(2,2,3)
plot(abs(x_fft))
title('After fft')
xlabel('Sample number')
ylabel('Amplitude')
ylim([-1.1 10])
grid on