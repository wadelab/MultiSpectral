function led_tetra_doScan(session, dpy, expt, sensors)
%  status=led_tetra_doScan(session, dpy, expt)
% This is the main loop that loads and runs the stimulus.  Data are loaded
% onto the DAC and are then run in Background mode - this allows the
% presentation to be interupted and a new stimulus loaded when it's 
% adjusted by the participant i.e. the stimulus does not need to complete 
% the pre-allocated duration.
% Authors : ARW and LW 10 July 2013
% Requires psychtoolbox 3.x

% Naturally lots of error checking here.
% (e.g check for the right inputs)


% %Check if dacData has already been set up
% if isfield(expt.stim,'dacData')==0
%     dataExistFlag=0;
% elseif isfield(expt.stim,'dacData')==1
%     dataExistFlag=1;
% end
%session.analogue.session.stop;

%We need to recreate the stim each time, so dataExistFlag has to be 0
dataExistFlag=0;
if(~dataExistFlag)
    stim=pry_makeAnalogueStim(dpy,session,expt,sensors);
    
    % We have to convert raw contrast levels to LED normalized
    % amplitudes. Normalized between 0 (off) and 1 (completely on).
    % Contrast runs between -1 and 1
    % But! Remember that backRGB is not necessarily the same for each
    % LED. So we have to add in the right baseline level.
    % We get this by repmatting backRGB
    baselineLevel=repmat(dpy.backRGB.dir(:)',size(stim.LEDContrast,1),1)*dpy.backRGB.scale;
    convertToPWM=(stim.LEDContrast/2)+baselineLevel; % The analogue stim runs around a mean of zero. which is wrong. Here we have to explicitly set the background so that the PWM can work...
    
    stim.dacData=pry_waveformToPWM(convertToPWM,expt.stim.temporal.sampleRate,session.analogue.session.Rate,100);
else
    % Assume that the stimulus.dacData is in place
    stim=expt;    
end

%Load the data onto the dac
vScale=5;
stim.dacData=vScale-stim.dacData*vScale;
stim.dacData(end,:)=mean(stim.dacData);  %sets the final values of the LEDs to the mean (so it doesn't turn off)

session.analogue.session.stop; %stop any Background data that is already running before queueing up next stim.
session.analogue.session.queueOutputData(double(stim.dacData));
session.analogue.session.startBackground();

end 





