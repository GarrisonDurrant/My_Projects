fn = fullfile(pwd,'d201sV2r06p0520211006.imb');

%[hdr,meta,dat] = APRDReadFile(fn,0,2000);
evalc('[hdr, meta, dat] = APRDReadFile(fn, 0, 2000);');

dat = dat(1:length(meta),:);

t = hdr.timeSync + [meta.timeStamp];

%4.3.1

data_n = hdr.nDataPoints;
start_freq = hdr.startFreq * 1e6;
stop_freq = hdr.stopFreq * 1e6;
sample_rate = hdr.sampleRate;
num_sweeps = (size(dat,1));

fprintf('Number of data points: %d\n', data_n);
fprintf('Start Frequency: %d MHz\n', start_freq/1e6);
fprintf('Stop Frequency: %d Mhz\n', stop_freq/1e6);
fprintf('Sample Rate: %f steps/s\n', sample_rate);
fprintf('Number Of Sweeps: %d\n\n', num_sweeps);

%4.3.2

freq_step = (stop_freq - start_freq) / (data_n - 1);
bandwidth = data_n * freq_step;
range_res = 3e8/ (2*bandwidth);
Rua = 3e8/(2*freq_step);

fprintf('Step Frequency: %f Khz\n', freq_step/1e3);
fprintf('Bandwidth: %f MHz\n', bandwidth/1e6);
fprintf('Range Resolution: %f meters\n', range_res);
fprintf('Unambiguous Range: %f meters\n\n', Rua);

%4.3.3

sweep_time = data_n/sample_rate;
sweeps_per_second = 1/sweep_time;
total_time = sweep_time * num_sweeps;

fprintf('Time for 1 Sweep: %f sec\n', sweep_time); %My calculation
fprintf('Sweeps Per Seconds: %f Hz\n', sweeps_per_second); %My calculation
fprintf('Total time of Sweep: %f sec\n', total_time); %My calculation


intervals = diff(t);         
actual_interval = mean(intervals);
total_duration = t(end) - t(1);

fprintf('Mean actual interval: %f seconds\n', actual_interval);
fprintf('Total duration: %f seconds\n', total_duration);

fprintf('Minimum interval: %f seconds\n', min(intervals));
fprintf('Maximum interval: %f seconds\n', max(intervals));

%4.4

%4.4.1

freq_num = linspace(start_freq, stop_freq, data_n);

figure(1)
plot(freq_num/1e6, 20*log10(abs(dat(1,:))));
xlabel('Frequencies in Mhz')
ylabel('Magnitude in dB')
title('Raw Spectrum of First Sweep')
grid on

%4.4.2

magnitude_dat = 20 * log10(abs(dat));

time = t - t(1);

figure(2)
imagesc(freq_num/1e6, time, magnitude_dat);
axis xy
xlabel('Frequencies in Mhz')
ylabel('Time in Seconds')
title('Raw Spectrum of dat')
colorbar
grid on

%4.5

%4.5.1

range = (0:data_n-1) * 3e8/(2*data_n*freq_step);

ifft_single_sweep = ifft(dat(1,:));

figure(3)
plot(range, 20*log10(abs(ifft_single_sweep)));
xlabel('Range in Meters')
xlim([0 329])
ylabel('Magnitude in dB')
title('IFFT of a single sweep')
grid on

%4.6

%4.6.1

range = (0:data_n-1) * 3e8/(2*data_n*freq_step);

win = hamming(data_n)';
single_sweep_win = ifft(dat(1,:) .* win);

figure(4)
plot(range, 20*log10(abs(ifft_single_sweep)))
hold on
plot(range, 20*log10(abs(single_sweep_win)))
hold off
grid on
legend('Sweep Without Window', 'Sweep With Window')
xlabel('Range in meters')
ylabel('Magnitude in dB')
title('Comparing Single Sweep With and Without Windowing')

[~, peak_index] = max(abs(ifft_single_sweep));
peak_range = range(peak_index);

figure(5)
plot(range, 20*log10(abs(ifft_single_sweep)))
hold on
plot(range, 20*log10(abs(single_sweep_win)))
hold off
legend('Without window', 'With Hamming window')
xlabel('Range (meters)')
ylabel('Magnitude (dB)')
title('Strongest Return')
xlim([peak_range-2 peak_range+2*10])
grid on

%4.7

%4.7.1

range = (0:data_n-1) * 3e8/(2*data_n*freq_step);

win = hamming(data_n)';
full_sweep_win = ifft(dat .* win, [], 2);

full_sweep_dB = 20*log10(abs(full_sweep_win));

time = t - t(1);

figure(6)
imagesc(time, range, full_sweep_dB.');
axis xy
xlabel('Time in Seconds')
ylabel('Range in Meters')
title('Complete Range/Time Plot of Data Set')
colorbar
grid on

cb = colorbar;
cb.Label.String = 'Magnitude (dB)';

peak_dB = max(full_sweep_dB(:));
clim([0 50])

%4.8

range = (0:data_n-1) * 3e8/(2*data_n*freq_step);

dat_mean = mean(dat,1);
dat_removed = dat - dat_mean;

win = hamming(data_n)';
full_sweep_win = ifft(dat_removed .* win, [], 2);

full_sweep_dB = 20*log10(abs(full_sweep_win));

time = t - t(1);

figure(7)
imagesc(time, range, full_sweep_dB.');
axis xy
xlabel('Time in Seconds')
ylabel('Range in Meters')
title('Range/Time Plot of Data Set with background removed')
colorbar
grid on

cb = colorbar;
cb.Label.String = 'Magnitude (dB)';

peak_dB = max(full_sweep_dB(:));
clim([0 20])

%4.9

c = 3e8;

center_freq = (1700e6 + 2400e6)/2;
wavelength = c/center_freq;

disp(newline)
disp(center_freq)
disp(wavelength)


velocity = 10 * 0.44704;
doppler = 2 * velocity / wavelength;

disp(newline)
disp(velocity)
disp(doppler)

sweep_rate = 1/mean(diff(t));

max_velocity = wavelength * sweep_rate / 4;
max_velocity_mph = max_velocity / 0.44704;

disp(max_velocity_mph)

%4.9.2

velocity = 4;

doppler = 2 * velocity / wavelength;
sweep_time = data_n / sample_rate;

range_shift = c * doppler * sweep_time / (2 * bandwidth);
range_resolution = c / (2 * bandwidth);

shift_in_bins = range_shift / range_resolution;
distance_traveled = velocity * sweep_time;

disp(range_shift)
disp(shift_in_bins)
disp(distance_traveled)