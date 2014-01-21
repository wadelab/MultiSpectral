function outWave=pry_waveformToPWM(inputWave,inputFrequency, carrierFreq,samplesPerBin)
% outWave=pry_waveformToPWM(inputWave,inputFrequency, carrierFreq,samplesPerBin)
% Takes an input waveform inputWave (t x n) with n channels of t timepoints
% Returns a pulse width modulated version. The inputWave will be clipped 
% between 0 and 1 and a warning will be thrown if higher vals are detected.
% Smaller ranges between these limits are fine.
% The output carrier frequency and samplesPerBin (the resolution) are
% supplied. Samples per bin should be a divisor of carrier frequency.
% ARW 041013 - wrote it

% TODO: Parameter checking

nInputPoints=size(inputWave,1);

inputDurationSecs=nInputPoints/inputFrequency; % This doesn't have to be an integer.


% For now, assum that inputWave has 1 channel
nChannels=size(inputWave,2);

nOutputPoints=carrierFreq*inputDurationSecs;

nOutputBins=nOutputPoints/samplesPerBin; % This should be an integer. For now we will pad it out...
if (fix(nOutputBins)~=nOutputBins)
    error('Non-integer number of bins in output: check your input and output frequencies and bin size');
end 
 

% Resample the input waveform at a lower frequency (1/samplesPerBin) to get
% the PWM values
samplePoints=linspace(1,nInputPoints,nOutputBins);

resampledInput=interp1(inputWave,samplePoints'); % linear interpolation is  okay

% Do clipping
if (sum(resampledInput>1))
    warning('Resampled input contains values >1: Clipping');
    resampledInput(resampledInput>1)=1;
end
if (sum(resampledInput<0))
    warning('Resampled input contains values <0: Clipping');
    resampledInput(resampledInput<0)=0;
end


outWave=mod(0:(nOutputPoints-1),samplesPerBin); % Sawtooth function
outWave=outWave/max(outWave(:));

outWave=repmat(outWave(:),1,nChannels);


compareWave=kron(resampledInput,ones(samplesPerBin,1));
outWave=outWave>compareWave;


