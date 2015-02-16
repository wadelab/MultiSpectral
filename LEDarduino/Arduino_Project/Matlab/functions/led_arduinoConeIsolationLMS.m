function [LEDStim] = led_arduinoConeIsolationLMS(dpy,stimLMS)
% [LEDvals] = ArduinoConeIsolationLMS(contrast, dir, LEDsToUse) 
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
LEDsToUse=dpy.LEDsToUse;


%% create cone fundamentals using Baylor nomogram
% Specify cone peaks and use same wavelength range as above for LED spectra
conepeaks=[557 530 437]; %for L M and S cones
wavelengths=dpy.WLrange; %wavelength range matches that used for LED spectra

coneSpectra=BaylorNomogram(wavelengths(:),conepeaks(:))';


%% set parameters of the trials so the stimulus can be built
% Set Display (dpy) values
dpy.maxValue=4.9; % These values are specific to  the pkm device: they are the biggest voltage and the voltage we want to modulate around
dpy.baseValue=2.5;



dpy.coneSpectra=coneSpectra;


%% Make the Stimulus

LEDStim=led_makeStimArduino(dpy,stimLMS); % This returns a structure with dir and scale that applies to the LEDs
 
% The returned structure gives values in dir and scale ranging betweek 0
% and 1. They are contrasts
% We want 1 (in the scale) to correspond to an absolute modulation of 1 * the
% background level.
% To turn these numbers into LED amplitudes that can be fed into the
% arduino, we need to multiply by the max Arduino output level x the
% background scale.



%error if negative numbers are produced - we will eventually build in code
%that indicates when contrast is too high/low and causes this problem.
if (sum(LEDStim.dir(:)<0))
   % disp(LEDStim.dir);
   % warning('Found negative numbers in scaled stim!');
   % LEDStim.dir(LEDStim.dir<0)=0;
end


