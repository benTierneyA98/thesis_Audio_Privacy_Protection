% Audio Privacy Protection
% Course/Year: DT021/4

% rmsEnergyValues.m
% Function for finding RMS energy values in signal
% using frame-by-frame analysis

function outputRmsValues = rmsEnergyValues(signal, frame_lgt, hop_length)

    rmsArray = [];
    
    for i = 1:frame_lgt:length(signal)
        % RMS equation to find RMS value in frame
        rms_current_frame = sqrt(sum(signal(i:i+frame_lgt).^2)/frame_lgt);
        rmsArray=[rmsArray, rms_current_frame]; % value stored in array
    end
    
    outputRmsValues = rmsArray;
end