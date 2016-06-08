function [LEDStim, dpy] = tetra_led_makeStimArduino(dpy,stimLMS)
% stim=makeStim(dpy,expt)
% Create the stimulus by inputting the following variables:
%
% dpy is the display structure. It should contain the spectra of each of
% the LEDs in steps of 2nm between 400 and 700nm
% dpy.spectra
% It can also contain a comment field dpy.comment and/or a peaks field
% dpy.peaks
% If only dpy.peaks is present this function will assume that the matrix
% dpy.peaks is a 2xn containing peak, FWHM for each of n LEDs.
% dpy must also contain channel numbers for each spectrum / peak.
%
% expt is a big structure containing
% expt.stim.temporal     freq
%                   duration
% expt.stim.chrom        stimLMS.dir
%                   stim.scale
%
%
% session is the structure returned from pry_openSession that contains
% information about the DAQ
% LW and ARW wrote it, 040813
%
% LW edited for use with different LED system Jan 2015
%TODO the comments need updating

%% Here we set up the cone fundamentals.
% First we check to see if cone spectra are defined in the dpy structure.
% If they are, we use them by default..
% Note: Here we take out the generation of the sine waves - this is done on
% the arduino now - our job here is to generate LED values.
% For each LED, we will send to the ardunio four sets of numbers: amplitude,
% frequency, duration and phase.

if isfield(dpy,'coneSpectra')
    %coneSpectra=dpy.coneSpectra;
else
    error('Could not find dpy.coneSpectra');
end 


%% Here we set up the LED spectra. Then with both cones and LED we can compute LED2CONE
if isfield(dpy,'LEDspectra')
else
    error('Could not find dpy.LEDspectra')
end

%% Determine the settings for each LED to achieve the maximum absorption of each cone:

%scale=expt.stim.chrom.stimLMS.scale;



[LEDStim, dpy]= tetra_sensor2primary(dpy,stimLMS);



 