function [LEDvals] = tetra_ArduinoConeIsolationLMS(contrast, dir, LEDsToUse)
% [LEDvals] = tetra_ßArduinoConeIsolationLMS(contrast, dir, LEDsToUse) 
% Uses the given contrast and direction to output the values for each LED.  
% LED values will be sent to the Arduino in a separate script.
%
% dir = [0 0 1];
% dir = contains an array of 3 (if LMS) numbers which specify the
% direction of the cone isolation, 
% e.g. for luminance, dir = [1 1 1]
% for L cone isolation dir = [1 0 0]
% LEDsToUse: Indices of LEDs that we want to modulate. E.g. [2 5 7] uses
% the blue, green and red LEDs from a 7 LED array on the 3D printed device.
% 
% contrast = .5;
% contrast = contains a single contrast value as a decimal (i.e. where 1 =
% 100%)
% e.g. contrast = .5   for 50% contrast
%
% Example for use in a script:
% LEDvals=ArduinoConeIsolationLMS(.4,[1 1 1],[2 5 7])
%
% Written by LEW 09/01/15

%% Load the Calibration data for the LEDs
load('LEDspectraScaled.mat'); %contains 1 column with wavelengths, then the LED calibs

%resample to specified wavelength range
WLrange=(380:2:720)';
for thisLED=1:size(LEDspectraScaled,2)-1;
    LEDspectra(:,thisLED)=interp1(LEDspectraScaled(:,1),LEDspectraScaled(:,1+thisLED),WLrange);
end
LEDspectra=LEDspectra(:,LEDsToUse); %specify which LEDs to use out of the 7


%% create cone fundamentals using Baylor nomogram
% Specify cone peaks and use same wavelength range as above for LED spectra
conepeaks=[557 530 437]; %for L M and S cones
wavelengths=WLrange; %wavelength range matches that used for LED spectra

coneSpectra=BaylorNomogram(wavelengths(:),conepeaks(:))';


%% set parameters of the trials so the stimulus can be built
% Set Display (dpy) values
dpy.maxValue=4.9; % These values are specific to  the pkm device: they are the biggest voltage and the voltage we want to modulate around
dpy.baseValue=2.5;
LEDspectra=LEDspectra-repmat(min(LEDspectra),size(LEDspectra,1),1);

dpy.LEDspectra=LEDspectra./(repmat(max(LEDspectra),size(LEDspectra,1),1));
%dpy.LEDspectra=LEDspectra./(max(LEDspectra(:)));

dpy.coneSpectra=coneSpectra;

%base levels across LEDs
dpy.backLED.dir=ones(1,size(LEDspectra,2)); %set the backLEDs to 1 for the 
%number of LEDS (using 'size(LEDspectra,2)' means if you change the number of LEDs being used you
%dont have to manually change this too)
dpy.backLED.scale=0.2;

%Set the parameters of the trial
expt.blockDurSecs=10; %Duration of stimulus presentation, secs
expt.ISIsecs=2; %Inter stimulus interval, secs
expt.preStimSecs=1; %Pre-stimulus pause before the start of the trials, secs

expt.stim.temporal.freq=8; % each of these frequencies will be applied to each of the colours, 0freq will create a control (off-) stim
expt.stim.temporal.sampleRate=200; %this is the rate we sample the underlying wave form at. It is not the digitiser frequency.
expt.stim.temporal.duration=expt.blockDurSecs; % s

%% specify the cone direction to be isolated and the contrast using input
%variables
expt.stim.chrom.stimLMS.dir=dir; %This defines the colour directions that we want to test
expt.stim.chrom.stimLMS.scale=contrast; % these are the contrasts that correspond to the the above directions



%% Make the Stimulus

stim=makeStimArduino(dpy,expt);


%the outputted values are too small for use when added to
%arduino code.  They need to be scaled from the current range (i think it's 
% -1 to 1) to a scale of 0 to 255 (or higher if use the higher bit rate)
OriginalScale_Max=1;
OriginalScale_Min=-1;
OriginalScale_Range=(OriginalScale_Max-OriginalScale_Min);

ArduinoScale_Max=255;
ArduinoScale_Min=0;
ArduinoScale_Range=(ArduinoScale_Max-ArduinoScale_Min);

%convert the outputted stim values for each LED to the new scale
for thisStim=1:length(stim.LEDAmp);
   ScaledStim(thisStim)=(((stim.LEDAmp(thisStim)-OriginalScale_Min)*...
       ArduinoScale_Range)/OriginalScale_Range)+ArduinoScale_Min;
end

%error if negative numbers are produced - we will eventually build in code
%that indicates when contrast is too high/low and causes this problem.
if (sum(ScaledStim(:)<0))
disp(ScaledStim);
error('Found negative numbers in scaled stim!');
ScaledStim=abs(ScaledStim);
end

LEDvals=ScaledStim; %set ScaledStim as the output variable LEDvals
end
