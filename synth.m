%%%%%%%%%%%%%%%%%%% USAGE %%%%%%%%%%%%%%%%%%%%%%%

% Set micID under microphone parameters to the input audio source
% Use setAudioSource.m to display a list of possible audio sources
% Then just run this file and play. 

% If you don't have a keyboard, try
% http://www.youtube.com/watch?v=EBZRzm98rX4
% Start playing the youtube video for a bit, then run this file and watch
% it locate where the video is at. Make sure to set volume to maximum 

% noise_thresh may have to be changed - it depends on your input audio
% 0.5 was used for direct audio out/mic in connection with the keyboard
% 0.005 is for having my computer play to itself from the youtube link on
% max volume

% There is no upload music functionality yet :( The music information
% is stored in final.mat

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all;
clear all;
cMost

% Microphone parameters
Fs = 96000; %mic sampling frequency
nBits = 16; %mic resolution
nChannels = 1; %mono (2 for stereo)
micID = 1; %input audio source, use setAudioSource.m to find
noise_thresh = 0.005; %might have to be adjusted for different mics

% Sampling parameters
t_pause = 0.2; %seconds between getaudiodata calls
L = 8192; %length of sample for FFT
t_reset = 0.5; %pause after restart (seconds)
resetTime = 120; %time before reset (seconds)

num_features = 12;%96;

load('lotr.mat');
mono = single(reshape(stereo,1,numel(stereo)));
clear stereo
windowSize = 2^13;
numWindows = floor(length(mono)/windowSize);
mono = mono(1:windowSize*numWindows);
monoWindowed = reshape(mono,windowSize,numWindows);
clear mono
harmonies = letterFFT(monoWindowed, 2*96000);
harmonies = reshape([harmonies; harmonies],num_features,2*size(harmonies,2));
clear monoWindowed

N = size(harmonies,2);
table = [zeros(1,N); inf(N-1,N)];
counter = 2;
volume = 0;

% Initialize Plotting
figure(1)

load('lotr.mat')

%{a
subplot(2,1,2)
h_line = plot(2*70/N*(1:N),zeros(N,1));
set(gca,'xlim',[0,70]);
set(gcf,'deletefcn','stop(h); stopping = 1;')

set(gca,'Position',[0.1, 0.05, 0.8, 0.1]);
%}


% Images
imPos = 0;
newPos = 0;
const = 0.1;
timeScale = 10833/70;%2100/70;%2155/70;


subplot(2,1,1)
h_im = imshow(img(1:1600,:));

set(gca,'Position',[0.05,0.2,0.9,0.7])



% Initialize Microphone
h = audiorecorder(Fs,nBits,nChannels,micID);

% Initialize Data Vectors
record(h);
pause(t_pause);

y_raw = getaudiodata(h); %raw vector from microphone
tic; %timing to not read microphone too fast

% Initializing Reset
t_unReset = 0; %time since last reset
resetting = 0;

y = y_raw(1:L); %sample for FFT
yInd = L; %last index of current sample



% Other
stopping = 0;
nowSilent = 1;

thing = 0;
while(~stopping)
    %store new microphone data
    if toc > t_pause && ~resetting
        y_raw = getaudiodata(h);
        t_unReset = t_unReset + toc;
        tic
    end
    
    %{a
    %Resetting
    if t_unReset > resetTime
        stop(h); record(h); tic;
        resetting = 1;
        t_unReset = 0;
        disp('Mic Reset')
    end
    if toc > t_reset && resetting
        y_raw = getaudiodata(h);
        yInd = 0;
        tic
        resetting = 0;
    end
    %}
    
    %get next FFT sample from stored microphone data
    while (length(y_raw) - yInd) >= L
        y = y_raw((yInd+1):(yInd+L));
        yInd = yInd + L;
        
        
        % CHECK FOR SILENCE
        volume = max(volume * 0.9, max(y));
        if (volume < noise_thresh) 
            counter = 2;
            if ~nowSilent   
                stop(h); record(h); tic;
                resetting = 1;
                t_unReset = 0;
                disp('Mic Reset')
                
                nowSilent = 1;
                disp('silent')
                table(2:counter,:) = inf;
                table(1,:) = 0;
            end

            drawnow
        else
            nowSilent = 0;
            
            % BEGIN PATTERN RECOGNITION
            yHarmonies = letterFFT(y,Fs);

            for j=2:N
                table(counter,j) = min (table(counter-1,max(1,j-4):j-1)) + norm( (yHarmonies - harmonies(:,j)));
            end
            counter = counter + 1;
            [~,loc] = min(table(counter,:));
            measure = round(70 * loc / N);
            % END PATTERN RECOGNITION
        end
        
        %Update image position
        [m,indexThing] = min(table(counter-1,1:(N/2)));
        %disp(2*171/N*indexThing)
        
        if ~nowSilent
            newPos = timeScale * 2*70/N * indexThing;
        end
        
        imPos = imPos + (newPos - imPos) * const;
        
        set(h_im,'CData',img(round(imPos)+(1:1600),:));
        
        
        %set(h_line,'YData',y);
        set(h_line,'YData',table(counter-1,:));
        
        
    end
    
    if resetting
        pauseTime = t_reset - toc;
    else
        pauseTime = t_pause - toc;
    end
    pause(pauseTime)
    
    thing = thing + 1;
    title([num2str(thing),'runs  ',num2str(pauseTime),'paused  ',num2str(toc),'elapsed']);
end
    
