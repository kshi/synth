function letterMag = letterFFT(y,Fs)

persistent note_ref NFFT f note_freqs convMat prev_Fs prev_L

%L = length(y);
[L, numSeries] = size(y);

recalc = 0;
if isempty(note_ref) 
    recalc = 1;
else
    if prev_Fs ~= Fs || prev_L ~= L
        recalc = 1;
    end
end

if recalc
    note_ref = 440*1.059463.^(-48:47)'; %39

    NFFT = 2^nextpow2(L); % Next power of 2 from length of y
    f = Fs/2*linspace(0,1,NFFT/2+1);

    note_freqs = knnsearch(f',note_ref);
    
    convMat = [repmat([1; zeros(11, 1)], 7, 1); 1];
    
    prev_Fs = Fs;
    prev_L = L;
end

Y = fft(y,NFFT)/L;
sig = 2*abs(Y(1:NFFT/2+1,:));

note_mag = sig(note_freqs,:);

letterMag = conv2(note_mag, convMat,'valid');

%%%%
ave = abs(mean(letterMag))+0.001;
letterMag = letterMag./(repmat(ave,12,1));

