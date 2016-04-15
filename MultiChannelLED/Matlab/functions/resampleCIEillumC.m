function [illumC,WLused] = resampleCIEillumC(WL)
% Load in the CIE illuminant C spectral power distribution and resample at 
% the specified wavelength range.
% 
% Requires psychtoolbox in path.
%
% input:
%       WL = range of wavelength values, either as an array of specified 
%            when calling the function, e.g. [380:1:720]
%
% output:
%       illumC = the spectral power distribution of illuminant C, sampled
%                at the specified wavelength
%       WLused = outputs the wavelengths used for the resampling
%
% written by LEW 02/09/15

% load in the spectral power distribution for CIE illuminant C
 load('spd_CIEC.mat');
 
% calculate original wavelength range using the contents of 'spd_CIEC'.
% 'S_CIEC' contains starting wavelength, step size, and total number of
% steps (including starting wavelength) e.g. [380,5,81]

originalWL = S_CIEC(1):S_CIEC(2):(S_CIEC(1)+(S_CIEC(2)*(S_CIEC(3)-1)));

% check that the desired wavelength is within the limits of the min and max
% wavelength values possible from spectra

if min(originalWL)<min(WL) && max(WL)<max(originalWL)
    WLused = WL;
    disp('WL values entered are within possible range')
else
    theError=sprintf('Wavelength range entered falls outside max range (%d to %d)',min(originalWL),max(originalWL));
    error((theError));
end
    
% interpolate the spd ('spd_CIEC') into the desired wavelength range

illumC = interp1(originalWL,spd_CIEC, WLused);

end
