function [relativeLEDlevels, LEDspectra] = LED2illumC(LEDcalib,dpy)
% [relativeLEDlevels, LEDspectra] = LED2illumC
% 
% Calculate necessary LED values needed to produce a white light (based on
% CIE illuminant C), which can be used as a baseline value in LED stimulus
%
% Input:
%       LEDspectra = the LED calibration spectra
%       dpy        = the structure containing the required WL range
%
% Output:
%       relativeLEDlevels = the relative intensity for each LED needed to
%                           produce the illuminant C
%       LEDspectra        = resampled LED calibration spectra
%
% Psychotoolbox should be in path, along with the folder containing
% necessary LED spectra files.
%
% written by LEW 03/09/15

% Set the WL values
WL = dpy.WLrange;

% resample the CIE illuminant C spectra to match desired wavelength range
[illumC,~] = resampleCIEillumC(WL);

% resample the LED spectra using wavelength range
for thisLED = 1:size(LEDcalib,2)-1 % column1 is wavelengths
    LEDspectra(:,thisLED) = interp1(LEDcalib(:,1),LEDcalib(:,1+thisLED),WL);
end
LEDspectra(LEDspectra<0) = 0; %set any negative values to 0

% multiply illuminant C by the LED spectra to get the LED values
% necessary to produce illuminant C light
LED2spec = illumC'*LEDspectra;

% normalise the outputted LED values
relativeLEDlevels = LED2spec./(max(LED2spec));

end