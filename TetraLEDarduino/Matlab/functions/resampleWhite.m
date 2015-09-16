function [white,WLused] = resampleWhite(WL)
% Load in the 'Philly white' spectral power distribution and resample at 
% the specified wavelength range. Measurements from psychotoolbox were done
% on bright day from white paper in DB's office.
% 
% Requires psychtoolbox in path.
%
% input:
%       WL = range of wavelength values, either as an array of specified 
%            when calling the function, e.g. [380:1:720]
%
% output:
%       white = the spectral power distribution of white paper reflectance, sampled
%                at the specified wavelength
%       WLused = outputs the wavelengths used for the resampling
%
% written by LEW 02/09/15

% load in the spectral power distribution for white reflectance
 load('spd_phillybright.mat');
 
% calculate original wavelength range using the contents of 'spd_phillybright'.
% 'S_CIEC' contains starting wavelength, step size, and total number of
% steps (including starting wavelength) e.g. [380,5,81]

originalWL = S_phillybright(1):S_phillybright(2):(S_phillybright(1)+(S_phillybright(2)*(S_phillybright(3)-1)));

% check that the desired wavelength is within the limits of the min and max
% wavelength values possible from spectra

if min(originalWL)<min(WL) && max(WL)<max(originalWL)
    WLused = WL;
    %disp('WL values entered are within possible range')
else
    theError=sprintf('Wavelength range entered falls outside max range (%d to %d)',min(originalWL),max(originalWL));
    error((theError));
end
    
% interpolate the spd ('spd_phillybright') into the desired wavelength range

white = interp1(originalWL,spd_phillybright, WLused);

end
