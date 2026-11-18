
Nfft = 8192;
T = 100e-6;
W_x = 100e3;
W_y = 1e6;
W_z = 10e6;
p = 1.2;

%3.2

%3.2.1
figure(1);
subplot(2,2,1);
x = git_chirp(T, W_x, p);

plot(real(x))
title('Chirp Pulse of 100KHz')
xlabel('Sample number')
ylabel('Real part of x')
grid on

%3.2.1
subplot(2,2,2);
y = git_chirp(T, W_y, p);

plot(real(y))
title('Chirp Pulse of 1MHz')
xlabel('Sample number')
ylabel('Real part of x')
grid on

%3.2.1
subplot(2,2,3);
z = git_chirp(T, W_z, p);

plot(real(z))
title('Chirp Pulse of 10MHz')
xlabel('Sample number')
ylabel('Real part of x')
grid on

%Normalizing in frequency 3.2.2

figure(2);

fft_x = fftshift(fft(x, Nfft));
fft_y = fftshift(fft(y, Nfft));
fft_z = fftshift(fft(z, Nfft));

f = (-floor(Nfft/2):ceil(Nfft/2)-1);

subplot(2,2,1);
plot(f, abs(fft_x));
title('100 kHz chirp spectrum')
xlabel('Normalize Frequency cycles/sample')
ylabel('Magnitude')
grid on

subplot(2,2,2);
plot(f, abs(fft_y));
title('1 MHz chirp spectrum')
xlabel('Normalize Frequency cycles/sample')
ylabel('Magnitude')
grid on

subplot(2,2,3);
plot(f, abs(fft_z));
title('10 MHz chirp spectrum')
xlabel('Normalize Frequency cycles/sample')
ylabel('Magnitude')
grid on


figure(3);

fft_x_norm = fftshift(fft(x, Nfft)) / sqrt(W_x);
fft_y_norm = fftshift(fft(y, Nfft)) / sqrt(W_y);
fft_z_norm = fftshift(fft(z, Nfft)) / sqrt(W_z);

f = (-floor(Nfft/2):ceil(Nfft/2)-1)/Nfft;
plot(f, abs(fft_x_norm),'y', 'linewidth', 2);
hold on

plot(f, abs(fft_y_norm),'r', 'linewidth', 1);
plot(f, abs(fft_z_norm),'b', 'linewidth', 1);
hold off

legend('100 kHz', '1 MHz', '10 MHz')
title('FFT - Magnitudes 3 Chirps')
xlabel('Normalize Frequency cycles/sample')
ylabel('Magnitude')

%Matched Filtering 3.3


%3.3.1
figure(4);
subplot(2,1,1);
x = git_chirp(T, W_y, 10);
plot(real(x))
title('Chirp Signal')
xlabel('Sample number')
ylabel('Real part of x')
grid on

%3.3.1
subplot(2,1,2)
pulse_x = ones(length(x), 1);
plot(pulse_x)
title('Simple Pulse')
xlabel('Sample Number')
ylabel('Magnitude')
grid on


delay = (-(length(x)-1):(length(x)-1)) / (10*1e6);

h_x = conj(flipud(x));

matched_filter_x = conv(x, h_x);

%3.3.2
figure(5)
plot(delay, abs(matched_filter_x), 'b');
hold on

h_x_pulse = conj(flipud(pulse_x));

matched_filter_x_pulse = conv(pulse_x, h_x_pulse);

%3.3.2
plot(delay, abs(matched_filter_x_pulse), 'r');
title('Matched Filter Output')
xlabel('Seconds')
ylabel('Magnitude')
legend('LFM Chirp', 'Simple Pulse')
%xlim([-1e-5 1e-5])
%ylim([0 1100])
hold off




%3.4

x = git_chirp(T, W_y, 10);
h_x = conj(flipud(x));
N = 2 * length(x) - 1;

matched_filter = conv(x, h_x);

X_fft = fft(x, N);
H_fft = fft(h_x, N);

delay = (-(length(x)-1):(length(x)-1)) / (10*1e6);

matched_filter_freq = ifft(X_fft .* H_fft);

%3.4.1 comparing the matched filter outputs
figure(6)
plot(delay ,abs(matched_filter_freq))
title('Chirp Frequency Spectrum')
xlabel('Normalize Frequency cycles/sample')
ylabel('Magnitude')
xlim([-1e-4 1e-4])
ylim([0 1000])
grid on



%3.4.2 

H_center = fftshift(H_fft);

win = zeros(N, 1);
win(901:1099) = hamming(199);

H_win = H_center .* win;

f = (-999:999)' * (10e6/N);

figure(7)
plot(f, abs(fftshift(X_fft))/max(abs(X_fft)))
hold on
plot(f, win)
hold off
legend('Chirp spectrum (scaled for display)', 'Hamming weights')
xlabel('Frequency (Hz)')
ylabel('Magnitude / weight')
xlim([-1e6 1e6])
grid on


%3.4.3

output_original = ifft(X_fft .* H_fft);
output_windowed = ifft(X_fft .* ifftshift(H_win));


original_dB = 20*log10(abs(output_original));
windowed_dB = 20*log10(abs(output_windowed));

figure(8)
plot(delay, original_dB)
hold on
plot(delay, windowed_dB)
hold off
legend('Without window', 'With Hamming window')
xlabel('Delay (seconds)')
ylabel('Magnitude (dB)')
xlim([-5e-6 5e-6])
grid on



%3.5

x = git_chirp(T, W_y, 10);
h_x = conj(flipud(x));
N = 2 * length(x) - 1;
delay = (-(length(x)-1):(length(x)-1)) / (10*1e6);

h_win = h_x .* hamming(length(h_x));

output_win = conv(x, h_x);

matched_filter_win = conv(x, h_win);

original_dB = 20*log10(abs(output_win));
windowed_dB = 20*log10(abs(matched_filter_win));

figure(9)
plot(delay, original_dB)
hold on
plot(delay, windowed_dB)
hold off
legend('Without window', 'With Hamming window')
xlabel('Delay (seconds)')
ylabel('Magnitude (dB)')
xlim([-5e-6 5e-6])
grid on


% %3.6
% x = git_chirp(T,W_y, 2);
% 
% pulse_x = ones(length(x), 1);
% 
% echo = zeros(401,1);
% 
% echo(101:300) = echo(101:300) + pulse_x;
% echo(141:340) = echo(141:340) + pulse_x;
% 
% figure(10)
% subplot(2,1,1)
% plot(echo);
% title('Plot of Received Echo')
% xlabel('Sample Number')
% ylabel('Magnitude')
% ylim([0, 2.2])
% 
% %matched filter for simple pulse
% 
% h_echo = conj(flipud(pulse_x));
% matched_filter_echo = conv(echo, h_echo);
% 
% samples = 1:length(matched_filter_echo);
% 
% %range = 20000 + (samples - 1)*75;
% samples = 1:length(matched_filter_echo);
% range = 20000 + (samples - length(pulse_x))*75;
% 
% subplot(2,1,2)
% plot(range, abs(matched_filter_echo))
% title('Matched Filter of the Echo')
% xlabel('Range (km)')
% ylabel('Magnitude')
% 
% %ylim([0, 2.2])
% 
% %Matched filter for chirp
% 
% echo_chirp = zeros(401,1);
% 
% echo_chirp(101:300) = echo_chirp(101:300) + x;
% echo_chirp(141:340) = echo_chirp(141:340) + x;
% 
% 
% figure(11)
% subplot(2,1,1)
% plot(abs(echo_chirp));
% title('Plot of Received Signals from LFM')
% xlabel('Sample Number')
% ylabel('Magnitude')
% ylim([0, 2.2])
% 
% h_chirp = conj(flipud(x));
% h_chirp = h_chirp .* hamming(length(h_chirp));
% 
% matched_filter_chirp = conv(echo_chirp, h_chirp);
% 
% samples = 1:length(matched_filter_chirp);
% 
% range = 20000 + (samples - length(x))*75;
% 
% subplot(2,1,2)
% plot(range, abs(matched_filter_chirp))
% title('Matched Filter of the LFM Echo')
% xlabel('Range in Meters')
% ylabel('Magnitude')
% 3.6
x = git_chirp(T, W_y, 2);
pulse_x = ones(length(x), 1);

% Simple pulse echoes
echo = zeros(401,1);
echo(101:300) = echo(101:300) + pulse_x;
echo(141:340) = echo(141:340) + pulse_x;

% Simple pulse matched filter
h_echo = conj(flipud(pulse_x));
matched_filter_echo = conv(echo, h_echo);

% LFM chirp echoes
echo_chirp = zeros(401,1);
echo_chirp(101:300) = echo_chirp(101:300) + x;
echo_chirp(141:340) = echo_chirp(141:340) + x;

% LFM matched filter with Hamming window
h_chirp = conj(flipud(x));
h_chirp = h_chirp .* hamming(length(h_chirp));
matched_filter_chirp = conv(echo_chirp, h_chirp);

% Range axis for both matched filter outputs
samples = 1:length(matched_filter_echo);
range = 20000 + (samples - length(x))*75;

% Received echoes before filtering
figure(10)
clf

subplot(2,1,1)
plot(echo)
title('Received Simple Pulse Echoes')
xlabel('Sample Number')
ylabel('Magnitude')
ylim([0 2.2])
grid on

subplot(2,1,2)
plot(abs(echo_chirp))
title('Received LFM Echoes')
xlabel('Sample Number')
ylabel('Magnitude')
ylim([0 2.2])
grid on

% Both matched filter outputs on the same graph
figure(11)
clf

plot(range, abs(matched_filter_echo), 'LineWidth', 1.5)
hold on
plot(range, abs(matched_filter_chirp), 'LineWidth', 1.5)
hold off

legend('Simple pulse', 'LFM with Hamming window')
title('Two-Target Matched Filter Outputs')
xlabel('Range (meters)')
ylabel('Magnitude')
xlim([20000 50000])
grid on


%3.7

x = git_chirp(T,W_y,10);

x = x(:);

fs = 10 * 1e6;
n = (0:length(x)-1)';

FD = 1e6/10;

d = exp(1j*2*pi*FD*n/fs);

y = x .* d;

h = conj(flipud(x));

matched_filter_x = conv(x, h);

matched_filter_y = conv(y, h);

delay = (-(length(x)-1):(length(x)-1))/fs;

figure(12)
subplot(2,1,1)
plot(delay, abs(matched_filter_x))
xlabel('Delay (seconds)')
ylabel('Magnitude')
xlim([-20e-6 20e-6])

subplot(2,1,2)
plot(delay, abs(matched_filter_y))
xlabel('Delay (seconds)')
ylabel('Magnitude')
xlim([-20e-6 20e-6])


x_down = conj(x);
h_down = conj(flipud(x_down));


y_down = x_down .* d;
matched_filter_down = conv(y_down, h_down);

figure(13)
plot(delay, abs(matched_filter_y))
hold on
plot(delay, abs(matched_filter_down))
hold off
legend('Up-chirp with Doppler', 'Down-chirp with Doppler')
xlabel('Delay (seconds)')
ylabel('Magnitude')
xlim([-20e-6 20e-6])
grid on