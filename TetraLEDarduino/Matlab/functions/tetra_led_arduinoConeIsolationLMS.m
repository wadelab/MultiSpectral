function [LEDStim,dpy] = tetra_led_arduinoConeIsolationLMS(dpy,stimLMS)
% [LEDStim] = tetra_led_arduinoConeIsolationLMS(dpy,stimLMS)
% Uses the variables in dpy and stimLMS to output the values for each LED.  
% LED values will be sent to the Arduino in a separate script.
%
%
% Written by LEW 09/01/15
% edited by LEW 21/05/15 - compatible with 5LEDs controlled by arduino DUE

%% Load the Calibration data for the LEDs
LEDsToUse=dpy.LEDsToUse;


%% create cone fundamentals using stockman cone fundamentals
% TODO - edit so dir==4 also works for TESTLM condition
if length(stimLMS.dir)==4 %if tetra stim
    LprimePos=dpy.LprimePosition; %position of peak between the L and M cones, 0.5 is half way
    coneSpectra=creatingLprime(dpy); %outputs the L L' M S spectra, with first column containing wavelengths
    fprintf('LprimePos is %.2f\n',LprimePos);
elseif length(stimLMS.dir)==3; %if LMS stim
    coneSpectra=creatingLMSspectra(dpy);
elseif length(stimLMS.dir)==2;
    [coneSpectra,dpy]=creating2coneSpectra(dpy); %where 'LMpeak' is lambdaMax of the cone in longwavelength region
end
%check WL match in coneSpectra and dpy.WLrange
try 
    if dpy.WLrange==coneSpectra(:,1)
    %disp('wavelengths match')
    end
catch 
    error('Wavelength ranges used for dpy.WLrange do not match the dpy.coneSpectra wavelengths. Edit dpy.WLranges to match')
end
% specify the coneSpectra so that the stimulus can be built
dpy.coneSpectra=coneSpectra(:,2:end); %remove the wavelengths column

%replace NaNs with 0
for thisColumn=1:size(dpy.coneSpectra,2);
    for thisRow=1:size(dpy.coneSpectra,1);
        if isnan(dpy.coneSpectra(thisRow,thisColumn));
            dpy.coneSpectra(thisRow,thisColumn)=0;
        end
    end
end
            
%% Make the Stimulus

LEDStim=tetra_led_makeStimArduino(dpy,stimLMS); % This returns a structure with dir and scale that applies to the LEDs
 
% The returned structure gives values in dir and scale ranging betweek 0
% and 1. They are contrasts
% We want 1 (in the scale) to correspond to an absolute modulation of 1 * the
% background level.
% To turn these numbers into LED amplitudes that can be fed into the
% arduino, we need to multiply by the max Arduino output level x the
% background scale.



%%code can take negative values now, so no need to error 
% if (sum(LEDStim.dir(:)<0))
%    disp(LEDStim.dir);
%    %warning('Found negative numbers in scaled stim! Contrast too high');
%    % LEDStim.dir(LEDStim.dir<0)=0;
% end


