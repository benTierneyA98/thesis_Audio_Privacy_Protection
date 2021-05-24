% Audio Privacy Protection
% Course/Year: DT021/4

% Introduction:
% The purpose of this code is to read in an audio file and identify
% the samples that contain speech. Those samples will then subsequently
% be removed to obfuscate the audio recording so as to render speech 
% unintelligible while preserving other salient audio features.

% Methodology:
% The code is broken up into the following sections
% 1. Read in audio signal -  the signal and relevant labels are read
% by the program. For SNR testing the Gaussian white noise is also
% added here
% 2. Identification of blank samples - samples above defined threshold
% are identified using frame-by-frame analysis and written to a vector. 
% 3. Extract Root-Mean Square Energy - RMS values are calculated and
% relevant samples noted in vector.
% 4. Extract Zero-Crossing Rate - ZCR values are calculated and
% relevant samples noted in vector.
% 5. Accuracy test & Confusion matrix - performance metrics calculated.
% Output audio signal also initialised.
% 6. Plot Figures

% Variables/Arrays:
% x = input audio signal
% y = signal with added Gaussian white noise
% A = labels in numeric format
% blankSamplesVector = binary vector for non zero samples identified
% rmsVector = binary vector for rms samples identified
% zcrVector = binary vector for zcr samples identified
% testVector = binary vector containing sum of previous vectors

% Required Functions:
% rmsEnergyValues.m
% zcrValues.m
% awgn / Gaussian white noise function

clc; close all; clear all;

%---------------------------------------
% Section 1. Read in audio signal
%---------------------------------------

[x,fs] = audioread('train1.mp3');
N = length(x);

% Addition of Gaussian white noise, 10 is SNR in dB
y = awgn(x,10, 'measured');

% Labels created to benchmark speech samples
fileID = fopen('train1_labels.txt','r');
formatSpec = '%f';
A = fscanf(fileID,formatSpec);

%----------------------------------------
% Section 2. Identification of blank samples
%----------------------------------------

% blankSamplesVector used to identify samples above threshold, 
% non silent samples
blankSamplesVector = [zeros(N,1)];

% Set parameters for analysis
frame_duration = 0.1; % 0.1 of a second
frame_len = frame_duration*fs;
hopLen = frame_len/2;
num_frames = floor(N/frame_len);

% For loop to iterate through frames of input signal 
% and identify silent samples
for k = 1:num_frames
    
    frame = x((k-1)*frame_len + 1 : frame_len*k);
    max_val = max(frame); % find max value in frame
    
    %frame above threshold
    if(max_val > 0.1)
        %frame values 1 in vector
        blankSamplesVector((k-1)*frame_len + 1 : frame_len*k)=1; 
        
    
    %frame below threshold
    elseif(max_val <= 0.1)
        %frame values 0 in vector
        blankSamplesVector((k-1)*frame_len + 1 : frame_len*k)=0; 
    end
end


%----------------------------------------
% Section 3. Extract Root-Mean Square Energy
%----------------------------------------

% Vector to store values of RMS function
rmsVector = [zeros(N,1)];

% RMS function
finalRmsValues= rmsEnergyValues(x, frame_len, hopLen);

% Count for checking >5 frames in a row below threshold
count1=0;

% For loop to iterate through frames of input signal and identify RMS
% samples greater than 0.1
for k = 1:num_frames
    
    frame = x((k-1)*frame_len + 1 : frame_len*k);
    
    % frame above threshold
    if(finalRmsValues(k) > 0.1)
        rmsVector((k-1)*frame_len + 1 : frame_len*k)=1; %frame values 1 in vector
        count1=0;
        
    % frame below threshold
    % added condition that must be 5 frames in a row to initialise
    % zero values to vector
    elseif(finalRmsValues(k) <= 0.1)&&(count1<5)
        count1=count1+1;
    elseif(finalRmsValues(k) <= 0.1) &&(count1==5)
        rmsVector((k-6)*frame_len + 1 : frame_len*k)=0; %frame values 0 in vector
        count1=count1+1;
    elseif(finalRmsValues(k) <= 0.1) && (count1>5)
        rmsVector((k-1)*frame_len + 1 : frame_len*k)=0; %frame values 0 in vector
        count1=count1+1;
    end
end

%------------------------------------------
% Section 4. Extract Zero-Crossing Rate
%------------------------------------------

% Vector to store values of ZCR function
zcrVector = [zeros(N,1)];

% Resize signal for zcr analysis
unused_samples = mod(N, frame_len);
frames = reshape( x(1:(N-unused_samples)), frame_len, []);

% ZCR function
finalZcrValues= zcrValues(x, frames, num_frames, fs);


% For loop to iterate through frames of input signal and identify silent
% samples
for j = 1:num_frames
    frame = x((j-1)*frame_len + 1 : frame_len*j);
    
    %frame above threshold
    if(finalZcrValues(j) < 100)
        %frame values 1 in vector
        zcrVector((j-1)*frame_len + 1 : frame_len*j)=1; 
    
    %frame below threshold
    elseif(finalZcrValues(j) >= 100)
        %frame values 0 in vector
        zcrVector((j-1)*frame_len + 1 : frame_len*j)=0; 
    end
end

%------------------------------------------
% Section 5. Accuracy test & Confusion matrix
%------------------------------------------

% Formatting of labels from numeric values into binary values
% in accuracy vector using index values

% Odd index values
oddIndexVals = A(1:2:end) ;
oddIndexVals =oddIndexVals*fs;
oddIndexVals=floor(oddIndexVals);

% Make first value of labels =1
if oddIndexVals(1)==0
    oddIndexVals(1)=1;
end

% Even index values
evenIndexVals = A(2:2:end) ;
evenIndexVals = evenIndexVals*fs;
evenIndexVals=floor(evenIndexVals);

% Make labels fit to size of signal
if evenIndexVals(end)>N
    evenIndexVals(end)=N-1;
end

% Vector containing benchmark binary values for speech 
% created from labels
accuracyVector = [zeros(N,1)];
k=1;

% For loop for writing to accuracyVector
for j=1:size(oddIndexVals)
     for k=oddIndexVals(j):1:evenIndexVals(j)
        accuracyVector(k)=1;
     end
end

% testVector created using AND operation
testVector = blankSamplesVector | rmsVector;
testVector=double(testVector);

% Set performance metric values =0
truePositive=0;
trueNegative=0;
falsePositive=0;
falseNegative=0;

% For loop for comparing accuracyVector and testVector
for j=1:N
    if testVector(j)== accuracyVector(j) && testVector(j)==1
        truePositive=truePositive+1;
    elseif testVector(j)== accuracyVector(j) && testVector(j)==0
        trueNegative=trueNegative+1;
    elseif testVector(j)~= accuracyVector(j) && testVector(j)==1
        falsePositive=falsePositive+1;
    elseif testVector(j)~= accuracyVector(j) && testVector(j)==0
        falseNegative=falseNegative+1;
    end
end

rmsVector=rmsVector(:,1);
accuracyVector=accuracyVector(:,1);

% Confusion matrix displayed
C=confusionmat(accuracyVector,testVector);
confusionchart(C)
title 'Audio Privacy Protection Confusion Matrix'
C.XLabel = 'Predicted Class';
C.YLabel = 'True Class';

% Perfomance metrics calculated
accuracy=((truePositive+trueNegative)/N)*100;
inaccuracy=((falsePositive+falseNegative)/N)*100;
precision=(truePositive/(truePositive+falsePositive))*100;
sensitivity=(truePositive/(truePositive+falseNegative))*100;
specificity=(trueNegative/(trueNegative+falsePositive))*100;
NPV=(trueNegative/(trueNegative+falseNegative))*100;

% Initialise new audio signal with privacy protected using testVector
new_sig = zeros(N,1);
for j=1:N
    if testVector(j)==0
        new_sig(j) = x(j) ;
    elseif testVector(j)==1
         new_sig(j)=0;
    end
end

%------------------------------------------
% Section 6. Plot Figures
%------------------------------------------

subplot(5,1,1)
x = x(:,1);
plot(x)
axis tight
xlabel 'Samples'
ylabel 'Amplitude'
title 'Discrete-time signal'

subplot(5,1,2)
plot(accuracyVector)
axis tight
title 'accuracyVector user identified speech samples'

subplot(5,1,3)
plot(testVector)
axis tight
title 'algorithm identified speech samples'

subplot(5,1,4)
plot(finalRmsValues)
axis tight
xlabel 'Frames'
ylabel 'RMS'
title 'Root-Mean Square Energy'

subplot(5,1,5)
plot(finalZcrValues)
axis tight
xlabel 'Frames'
ylabel 'ZCR'
title 'Zero-Crossing Rate'