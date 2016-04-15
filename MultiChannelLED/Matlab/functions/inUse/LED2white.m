function [relativeLEDlevels, LEDspectra] = LED2white(LEDcalib,dpy)
% [relativeLEDlevels, LEDspectra] = LED2white(LEDcalib,dpy)
% 
% Calculate necessary LED values needed to produce a white light,
% which can be used as a baseline value in LED stimulus
%
% Input:
%       LEDcalib   = the LED calibration spectra (WLs and each LED)
%       dpy        = the structure containing the required WL range
%
% Output:
%       relativeLEDlevels = the relative intensity for each LED needed to
%                           produce the white light
%       LEDspectra        = resampled LED calibration spectra
%
% Psychotoolbox should be in path, along with the folder containing
% necessary LED spectra files.
%
% written by LEW 03/09/15

% Set the WL values
WL = dpy.WLrange;

%% resample the white spectra to match desired wavelength range
% load in the spectral power distribution for white reflectance
load('spd_phillybright.mat');
% calculate original wavelength range using the contents of 'spd_phillybright'.
% 'S_CIEC' contains starting wavelength, step size, and total number of
% steps (including starting wavelength) e.g. [380,5,81]
originalWL = S_phillybright(1):S_phillybright(2):(S_phillybright(1)+(S_phillybright(2)*(S_phillybright(3)-1)));

% check that the desired wavelength is within the limits of the min and max
% wavelength values possible from spectra. If so, interpolated into desired
% WL range
if min(originalWL)<min(WL) && max(WL)<max(originalWL)
    white = interp1(originalWL,spd_phillybright, WL);
    %disp('WL values entered are within possible range')
else
    theError=sprintf('Wavelength range entered falls outside max range (%d to %d)',min(originalWL),max(originalWL));
    error((theError));
end
   
%% resample the LED spectra using wavelength range
for thisLED = 1:size(LEDcalib,2)-1 % column1 is wavelengths
    LEDspectra(:,thisLED) = interp1(LEDcalib(:,1),LEDcalib(:,1+thisLED),WL);
end
LEDspectra(LEDspectra<0) = 0; %set any negative values to 0

%specify the LEDs that are in use
LEDspectra = LEDspectra(:,dpy.LEDsToUse);
cones = dpy.coneSpectra(:,2:end); %don't want WL col

%first find out what the cone vals are in response to the white spectra
white2cone = cones'*white; %get cone values in response to the white spectra

%produce a cones to led transform matrix
lms2led = LEDspectra'*cones; %get lms2led transform

%use the cone vals from white2cone and the lms2led transform to get the led
%vals necessary for 'white' cone response
whiteDir = lms2led * white2cone;
% normalise the outputted LED values
relativeLEDlevels = (whiteDir./(max(whiteDir)))';

end