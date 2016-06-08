function status=led_doScan_block(session, dpy, scan, expt, coneSensors)
%  status=led_doScan(session, dpy, scan)
% This is the main loop that runs the scan
% It presents  trials at predefined times 
% Data for the trials are loaded onto the DAC before they are run
% and then triggered in foreground mode at the appropriate time
% You have to ensure that trials do not overlap each other
% Authors : ARW and LW 19 Apr 2013
% Requires psychtoolbox 3.x

% Naturally lots of error checking here.
% (e.g check for the right inputs)

% We assume that the DAC is initializd for example. 

nTrials=length(scan.trials);
scanStartTime=GetSecs; % This is the current time in seconds when the scan starts. All the other elapsed times will be referenced off this.


trialstring=1;
for thisTrial=1:nTrials;   
    
    thisOnsetTime=scanStartTime+scan.trials(thisTrial).onsetTime; % Compute this once so that we don't compute it lots of times within a loop
    
    % Now compute the stim and upload it to the DAC
    % You have the option of precomputing the stims - we'll check dacData
    % to see if there's anything in there...
    
    % For now we assume one stim per trial. (Just to get the pilots
    % running). In real life we might have lots of stims / trial
    
    dataExistFlag=0;
    if(isfield(scan.trials(thisTrial).stimulus,'dacData'))
        if ~isempty(scan.trials(thisTrial).stimulus.dacData)
            dataExistFlag=1;
        end
    end 
    
        
    if(~dataExistFlag)
%         disp('Making stim');
        stim=pry_makeAnalogueStim_block(dpy,session,scan.trials(thisTrial).stimulus,expt,coneSensors);
        
        % We have to convert raw contrast levels to LED normalized
        % amplitudes. Normalized between 0 (off) and 1 (completely on).
        % Contrast runs between -1 and 1
        % But! Remember that backRGB is not necessarily the same for each
        % LED. So we have to add in the right baseline level. 
         % We get this by repmatting backRGB
         baselineLevel=repmat(dpy.backRGB.dir(:)',size(stim.LEDContrast,1),1)*dpy.backRGB.scale;
        convertToPWM=(stim.LEDContrast/2)+baselineLevel; % The analogue stim runs around a mean of zero. which is wrong. Here we have to explicitly set the background so that the PWM can work...
         
       stim.dacData=pry_waveformToPWM_block(convertToPWM,scan.trials(thisTrial).stimulus.temporal.sampleRate,session.analogue.session.Rate,100);
   % keyboard
    else
        % Assume that the stimulus.dacData is in place
        stim=scan.trials(thisTrial).stimulus;
    end
    
    %Load the data onto the dac
    vScale=5;
    stim.dacData=vScale-stim.dacData*vScale;
    stim.dacData(end,:)=mean(stim.dacData);
    
%   disp('Loading data to DAC');
    session.analogue.session.queueOutputData(double(stim.dacData));
   
%    
%      min(stim.dacData)
%      
%      max(stim.dacData)
%      mean(stim.dacData)
%      size(stim.dacData)
     
    % Here we enter a loop - wait until the current time is >= the trial
    % onset time
%         disp('Preparing');

    session.analogue.session.prepare;
    
%     get(session.analogue.session)

%             disp('Waiting');

    while ((GetSecs-scanStartTime)<scan.trials(thisTrial).onsetTime) %
        % Do nothing
    end
% session.analogue.session.startBackground();
% session.analogue.session.wait;

   status=session.analogue.session.startForeground();
%             disp('Run');
end % Go to the next trial





