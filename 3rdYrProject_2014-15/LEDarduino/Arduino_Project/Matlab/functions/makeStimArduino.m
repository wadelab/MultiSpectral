function stim=makeStimArduino(dpy,expt)
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
% Compute in 3 cone peaks and the wavelength range to produce Baylor Nomograms
% NOTE: For now ONLY LMS stim are okay.
% First we check to see if cone spectra are defined in the dpy structure.
% If they are, we use them by default..
% Note: Here we take out the generation of the sine waves - this is done on
% the arduino now - our job here is to generate LED values.
% For each LED, we will send to the ardunio three four numbers: amplitude,
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



[LEDStim]= sensor2primary(dpy,stimLMS);
LEDContrast=LEDStim.scale(:)*LEDStim.dir';

%expt.stim.chrom.noise.stimLMS.dir=[1 1 1];
%expt.stim.chrom.noise.stimLMS.scale=0.03;
%expt.stim.chrom.noise.type='white';
%expt.stim.chrom.noise.temporal=[10:20] %how do we apply random freq as
% If stim contains a noise field, we add in noise
% if (isfield(expt.stim.chrom,'noise'))
% 
% 
%     disp('Noise...');
%     noiseVals=(rand(size(LEDContrast))-0.5)*stim.chrom.noise.stimLMS.scale;
%     LEDContrast=LEDContrast+noiseVals;
%     LEDContrast(LEDContrast>1)=1;
%     LEDContrast(LEDContrast<-1)=-1;
%     
% end
% 
% % Convert these vals to voltages
% 
% %baseValue=dpy.baseValue; % increasing the base (and also the max) value will make the LED less bright (i.e. 1 is very bright, 5.5 is off)
% maxValue=dpy.maxValue;

%stimulus.data=(dpy.maxValue-dpy.baseValue)*LEDContrast+repmat(dpy.baseValue*dpy.backRGB.dir,length(modulation),1);
%stimulus.data=(dpy.maxValue)-stimulus.data;

stim.LEDAmp=LEDContrast*2; 



% We're done. stimulus should contain both the LEDContrast variations and
% the raw voltages.


% function stimRGB = cone2RGB(display,stimLMS,backRGB,sensors)
% %
% %   stimRGB = cone2RGB(display,stimLMS,[backRGB],[sensors])
% %
% %AUTHOR: Wandell, Baseler, Press
% %DATE:   09.10.98
% %PURPOSE:
% %
% %   Calculate the RGB values (stimRGB.dir, stimRGB.scale) needed
% %   to create a  stimulus defined by stimLMS.dir, stimLMS.scale
% %   and the backRGB.dir backRGB.scale values. 
% %   
% %   This code works for a single stimLMS.dir vector, but
% %   stimLMS.scale may be a vector.
% %   
% %   The returned values in stimRGB.scale are the RGB scale factors
% %   needed to obtain the specified LMS scale.  The cone contrast
% %   is calculated with respect to the background, as in
% %   
% %     (lmsStimPlusBack - lmsBack) ./ lmsBack
% %     
% %   
% % ARGUMENTS
% %
% %  display:  .spectra contains the monitor spectral, is needed
% %  stimLMS:  .dir    is the color direction of the contrast stimulus
% %            .scale  is the scale factor
% %            When the stimLMS.dir is cone isolating, the
% %            scale factor is the same as contrast.  The
% %            definition of a single contrast value is problematic for other
% %            directions. 
% %  backRGB:  (optional) .dir and  .scale define the mean RGB of background,
% %            so that backRGB.dir*backRGB.scale is a vector of
% %            linear rgb values.
% %  sensors:  (optional) A 361x3 matrix of sensor wavelength sensitivities.
% %            Default:  Stockman sensors.
% %
% % RETURNS
% %            
% % stimLMS:   .maxScale   the largest permissible scale (re gamut
% %            and background).
% % stimRGB:  .dir    color direction of the rgb vector
% %           .scale  vector of scale values.
% %            
% % SEE ALSO:
% %    findMaxConeScale(); RGB2Cone();
% %
% % ISSUES:
% %    It is a bit odd that we send in backRGB and stimLMS.  We did
% %   this because when we design the stimuli, we usually pick a
% %   background level near the middle of RGB, say [.5 .5 .5],
% %   without worrying much about it.  If we had sent in backLMS,
% %   it would usually be less convenient.
% %   
% % 98.11.04 rfd: made stockman persistent so that it needn't be
% % 				loaded from disk each time this is called.		
% % 98.11.17 rfd & wap: modified findMaxConeScale to 
% %				properly scale the requested stimLMS so that
% %				the resulting stimuli will have the requested LMS.
% %				(See findMaxConeScale for details.)
% % 2010.04.02 RFD: allow an rgb2lms matrix in place of diaplay & sensors
% 
% % Set up input defaults
% %
% if ~exist('backRGB','var')
%   % disp('Cone2RGB: Using default background of [0.5 0.5 0.5]')
%   backRGB.dir = [1 1 1]';
%   backRGB.scale = 0.5;
% end
% 
% if(~isstruct(display) && numel(display)==9)
%     % then display is a 3x3 rgb2lms matrix.
%     rgb2lms = display;
% else
%     if ~exist('sensors', 'var')
%         % disp('Cone2RGB: Using Stockman fundamentals')
%         % keep sensors in memory so that they aren't loaded each time
%         persistent stockman;
%         
%         % We think the matlab file 'stockman' may be stored differently in
%         % ISET and vistadisp.  The LMS spectra are in a variable called
%         % 'stockman' in one case and 'data' in the other. We check for
%         % both.
%         if ~exist('stockman', 'var') || isempty(stockman)
%             tmp = load('stockman');
%             if isfield(tmp, 'stockman'), stockman = tmp.stockman; end
%             if isfield(tmp, 'data'),     stockman = tmp.data;     end            
%         end
%         
%         sensors = stockman;
%     end
%     if ~isfield(display,'spectra')
%         error('The display structure requires a spectra field');
%     end
%     rgb2lms = sensors'*display.spectra;
% end
% 
% [stimLMS stimRGB] = findMaxConeScale(rgb2lms,stimLMS,backRGB);
% 
% for ii=1:length(stimLMS.scale)
% 	if (stimLMS.scale(ii) > stimLMS.maxScale)
% 		if (stimLMS.scale(ii)-stimLMS.maxScale < 0.001)
% 			stimLMS.scale(ii) = stimLMS.maxScale;
% 		else
% 	      	error('Requested contrast ( %.3f) exceeds maximum (%.3f)\n', stimLMS.scale(ii),stimLMS.maxScale);
% 		end  
% 	end
%     % When stimRGB.scale equals stimRGB.maxScale, 
%     % 
%     %      stimLMS.scale = stimLMS.maxScale
%     % 
%     % Everything is linear, so to obtain 
%     % 
%     %    stimLMS.scale = stimLMS.maxScale * (stimRGB.scale/stimRGB.maxScale)
%     % 
%     % To solve for the stimRGB.scale that yields a stimLMS.scale,
%     % we invert
%     % 
%     stimRGB.scale(ii) = (stimLMS.scale(ii)/stimLMS.maxScale)*stimRGB.maxScale;
%     %   
% end
% 
% return
% 
% % Debugging
% % Compute the stimulus contrast for the various conditions, as
% % a check.
% 
% lmsBack = rgb2lms*(backRGB.dir*backRGB.scale);
% for ii=1:length(stimRGB.scale)
%   lmsStimPlusBack = rgb2lms*(stimRGB.scale(ii)*stimRGB.dir) + lmsBack;
%   (lmsStimPlusBack - lmsBack) ./ lmsBack
% end

 