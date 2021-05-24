% Audio Privacy Protection
% Course/Year: DT021/4

% zcrValues.m
% Function for finding zero-crossing values in signal
% using frame-by-frame analysis

function outputZcrValues = zcrValues(input_audio, frames, n_frames, Fs)

    % take mean of frame away from values in frame
    for i=1:n_frames
        frames(:,i)=frames(:,i)-mean(frames(:,i));
    end

    % find sum of values <0, will give ZCR
    zcr = sum(frames(1:end-1, :).*frames(2:end, :)<0);
    outputZcrValues=zcr;
end