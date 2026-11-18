clear;
clc;
close all;

Fs = 4e6;
Fc = 1575.42e6;

% GPS matched filter impulse responses
prn_code_id = 1:37; % PRN code IDs for GPS satellites (32 + extras = 37)
for i=1:length(prn_code_id) 
    mf(:,i) = build_matched_filter(prn_code_id(i),Fs);
end
[ Nh,~] = size(mf); % Get the length of the matched filter impulse

% Parameters for fast convolution
N = 2^18; % FFT size [ samples ]
MF = fft(mf,N) ; % Compute zero - padded DFT of matched filters for
    %frequency - domain processing

% Parameters for doppler frequency search
Fmax = 8000; % Maximum doppler frequency [ Hz ]
Fmin = - Fmax ; % Minimum doppler frequency [ Hz ]
Fbin = Fs / N ; % FFT bin width [ Hz ]
KFmax = ceil (Fmax / Fbin) ; % Number of frequency bins ( positive side )
KFmin = floor (Fmin / Fbin) ; % Number of frequency bins ( negative side )
ksearch = KFmin:KFmax ; % Set of bins for doppler frequency search
Fsearch = ksearch * Fs / N ; % Frequency vector for plotting


fid = fopen('gps.dat','rb'); % Open the file for binary read
Nx = N - Nh + 1; % Number of data samples so that Nx + Nh - 1 = N
x = fread(fid ,2 * Nx ,'int16=>float32'); % Read samples and convert from
    %short to float
fclose ( fid ) ; % Close the file
x = complex(x(1:2:end), x(2:2:end));

NFFT = 2^15;
fx = (0:NFFT-1)/NFFT - 0.5;

Fx = fx*Fs + Fc;
X = abs(fftshift(fft(x,NFFT)));
figure(1)
subplot(211); plot(Fx/1e6,20*log10(X)); axis tight; grid on
subplot(212); plot(fx,20*log10(X)); axis tight; grid on

X = fft(x,N);

peak_results = zeros(1, size(MF,2));
best_doppler = zeros(1, size(MF,2));
best_delay = zeros(1, size(MF,2));

for i=1:size(MF,2)
    max_val = 0;
    for k=1:length(ksearch)
        X_cyc = circshift(X, -ksearch(k));
        Y = X_cyc .* MF(:,i);
        y = ifft(Y); 

        y_trimmed = abs(y(1:8000));

        [current_max, current_idx] = max(y_trimmed);

        if current_max > max_val
            max_val = current_max;
            peak_results(i) = current_max;
            best_doppler(i) = ksearch(k) * (Fs/N); 
            best_delay(i) = (current_idx - 1) / Fs;
        end

    end
end

threshold = 6e4;
visible = peak_results > threshold;

fprintf('\nVisible Satellites:\n');
fprintf('PRN\tDelay (s)\t\tDoppler (Hz)\tPeak\n');

for i = 1:length(peak_results)
    if visible(i)
        fprintf('%d\t%.6e\t%.2f\t\t%.2e\n', ...
            i, best_delay(i), best_doppler(i), peak_results(i));
    end
end

figure(2);
stem(1:length(peak_results), peak_results, 'filled', 'LineWidth', 1.5);
hold on;

detected_idx = find(visible);
stem(detected_idx, peak_results(detected_idx), 'r', 'LineWidth', 2);

xlabel('Satellite Index');
ylabel('Peak Amplitude'); 
title('Satellite Visibility');
grid on;
set(gca, 'XTick', 1:37);

hold off;

sat_idx = 32; 
all_traces = zeros(length(ksearch), 4000); 

for k = 1:length(ksearch)
    X_cyc = circshift(X, -ksearch(k)); 
    Y = X_cyc .* MF(:, sat_idx);
    y = ifft(Y);
    all_traces(k, :) = abs(y(1:4000));
end

figure;
plot((0:3999)/Fs, all_traces');
xlim([0.915e-3, 0.93e-3]);
xlabel('Delay [seconds]'); ylabel('Amplitude');
title('Delay');

peak_per_doppler = max(all_traces, [], 2);

figure;
imagesc(Fsearch, (0:3999)/Fs, all_traces'); 
set(gca, 'YDir', 'normal');
colorbar;
xlabel('Doppler Frequency [Hz]');
ylabel('Delay [seconds]');
title('Doppler Frequency');

