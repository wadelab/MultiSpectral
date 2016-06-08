function status=led_doScan_block_Task(session, dpy, scan, coneSensors)
%  status=led_doScan_block_Task(session, dpy, scan, coneSensors)
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
%scanStartTime=GetSecs; % This is the current time in seconds when the scan starts. All the other elapsed times will be referenced off this.
scanStartTime=cputime;

% cues=(1:5:nTrials);
% TaskOnes=(2:5:nTrials);
% Stims=(3:5:nTrials);
% TaskTwos=(4:5:nTrials);
% Prompts=(5:5:nTrials);

for thisTrial=1:nTrials;   
    thisOnsetTime=scanStartTime+scan.trials(thisTrial).onsetTime; % Compute this once so that we don't compute it lots of times within a loop

    % the below code was designed to open a session with the necessary
    % number of LEDs and the appropriate spectra for it, in order for the
    % cue and prompt stim to be a single LED light - issues with linking
    % functions that do not work well with only 1 LED selected
%     if ismember(thisTrial,cues)
%         disp('cue')
%         session=pry_openSession(0,0,1);
%         dpy.spectra=dpy.cue.spectra;
%         dpy.backRGB.dir=dpy.cue.backRGB.dir;
%         scan.trials(thisTrial).stimulus.chrom.dir=1;
%         size(dpy.spectra,2)
%     elseif ismember(thisTrial,TaskOnes)
%         session=pry_openSession(0:3,0,1);
%         disp('taskone')
%         dpy.spectra=dpy.spectra;
%         dpy.backRGB.dir=dpy.backRGB.dir;
%         size(dpy.spectra,2)
%     elseif ismember(thisTrial,Stims)
%         session=pry_openSession(0:3,0,1);
%         disp('stim')
%         dpy.spectra=dpy.spectra;
%         dpy.backRGB.dir=dpy.backRGB.dir;
%         size(dpy.spectra,2)
%     elseif ismember(thisTrial,TaskTwos)
%         session=pry_openSession(0:3,0,1);
%         disp('task two')
%         dpy.spectra=dpy.spectra;
%         dpy.backRGB.dir=dpy.backRGB.dir;
%         size(dpy.spectra,2)
%     elseif ismember(thisTrial,Prompts)
%         disp('prompt')
%         session=pry_openSession(0,0,1);
%         dpy.spectra=dpy.prompt.spectra;
%         dpy.backRGB.dir=dpy.prompt.backRGB.dir;
%         scan.trials(thisTrial).stimulus.chrom.dir=1;
%         size(dpy.spectra,2)
%     end

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
        stim=pry_makeAnalogueStim_block_Task(dpy,session,scan.trials(thisTrial).stimulus,coneSensors);
        
        % We have to convert raw contrast levels to LED normalized
        % amplitudes. Normalized between 0 (off) and 1 (completely on).
        % Contrast runs between -1 and 1
        % But! Remember that backRGB is not necessarily the same for each
        % LED. So we have to add in the right baseline level. 
         % We get this by repmatting backRGB
         baselineLevel=repmat(dpy.backRGB.dir(:)',size(stim.LEDContrast,1),1)*dpy.backRGB.scale;
        convertToPWM=(stim.LEDContrast/2)+baselineLevel; % The analogue stim runs around a mean of zero. which is wrong. Here we have to explicitly set the background so that the PWM can work...
        stim.dacData=pry_waveformToPWM_block_Task(convertToPWM,scan.trials(thisTrial).stimulus.temporal.sampleRate,session.analogue.session.Rate,100);
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

%%%%%%% GetSecs not working as at 6th Aug, the time doesn't refresh...
%%%%%%% GetSecsTest errored with "Test failed, because could not disable
%%%%%%% 1khZ timer Interrupts".  Try again soon...
while (cputime<thisOnsetTime)
    % Do nothing
end

  session.analogue.session.startForeground();
   
%Output details of each trial (the chrom direction and the frequency)as
% the trials are carried out
nTrials=length(scan.trials);
StartSeq=(1:5:nTrials);
thisLabel=thisTrial;
if ismember(thisLabel,StartSeq);
    IndSeqNum=thisLabel==StartSeq;
    SeqNum=find(IndSeqNum);
      
    [trialChrom]=scan.trials(thisLabel+2).stimulus.chrom.dir; %output the chrom direction of the tetra stim
    [trialFreq]=scan.trials(thisLabel+2).stimulus.temporal.freq; %output the Freq of the tetra stim
    [trialDur]=scan.trials(thisLabel+2).stimulus.temporal.duration; %output the duration of the tetra stim
    
    [taskOneFreq]=scan.trials(thisLabel+1).stimulus.temporal.freq; %output the freq of the task stims
    [taskTwoFreq]=scan.trials(thisLabel+3).stimulus.temporal.freq;
    
    %Display the trial number and the Chrom and Freq values for that trial
  
        disp(['Sequence: ', num2str(SeqNum)])
        disp(['      Stim Direction: ', num2str(trialChrom)])
        disp(['      Stim Frequency: ', num2str(trialFreq)])
        disp(['      Stim Duration: ', num2str(trialDur)])
        disp('     ')
        disp(['      Task 1 Frequency: ', num2str(taskOneFreq)])
        disp(['      Task 2 Frequency: ', num2str(taskTwoFreq)])
end
  
  
  
            %disp('Run');
end % Go to the next trial
end %go to next element




