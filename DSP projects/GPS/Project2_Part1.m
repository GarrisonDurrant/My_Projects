
clear;
clc;

[xn,fs_xn]=audioread('speech.wav');               
n=length(xn); %length of xn

[hn,fs_hn]=audioread('impulse_cathedral.wav');               
m=length(hn); %length of hn

disp(n);
disp(m);

disp(fs_xn);
disp(fs_hn);

%Convolution Method 1: for loops. Write MATLAB convolution code that uses for loops to
%compute convolution.

tic; %Start timer for Method 1

tot_L = (n + m) - 1;%Find L by n + m - 1

yn1(tot_L) = 0; %Create a yn array that is of size L and fill with 0's

for i = 1:tot_L %For loop to iterate 1-L times
    index_value = 0; %Set index_value to 0 so values do not accumulate for each index of yn
    for k = 1:n %For loop to iterate from 1-n times for all the x values
        h_idx = i - k + 1; %Finding the correct h index to multiply by
        if (k >= 1 && k <= length(xn)) && (h_idx >= 1 && h_idx <= length(hn)) %Ensure we don't leave the array
            index_value = index_value + (xn(k) * hn(h_idx)); %Compute value for current y index
        end
    end
    yn1(i) = index_value; %Place index_value into the correct y index
end

%disp(yn); %Display the yn output

time_loop = toc; %Stop timer for Method 1

len_y = length(yn1);
disp(len_y);

%Convolution Method 2: FFT products. Write MATLAB code to zero pad, transform,
%multiply, and inverse transform as explained in the procedure above.

tic; %Start Timer for Method 2

N = 131072; % N > n + m - 1 and rounded up to neared 2^k

xn(N) = 0; %Zero padding xn
hn(N) = 0; %Zero padding hn

Xk = fft(xn); %Computing fft of xn
Hk = fft(hn); %Computing fft of hn

Yk = Xk .* Hk; %Multiplying matrices in frequency domain to find Yk



yn2 = ifft(Yk); %Computing the invers fft

%disp(yn); %Displaying the final yn array

time_fft = toc; %Stop timer for Method 2

fprintf('Method 1 took %.6f seconds\n', time_loop); %Display timer for Method 1
fprintf('Method 2 took %.6f seconds\n', time_fft); %Display timer for Method 2

% Force to columns first
y1 = yn1(:); 
y2 = yn2(:);

minLength = min(length(y1), length(y2));
r = corr(y1(1:minLength), y2(1:minLength));

disp(r);