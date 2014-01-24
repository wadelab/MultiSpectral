function tetrachrom_block_Task(ExptID,SubjectID,SessionNum)
% tetrachrom_block_Task(ExptID,SubjectID,SessionNum)
% This function creates tetra stimuli of varying contrasts and durations to
% produce a block of stimuli that is presented in a randomised order.  
% A task is also added to either side of this stimulus - the participant
% has to judge which of two stimuli (presented either side of the tetra stim)
% was flickering faster and press a key to indicate whether it was the first or 
% second presentation [N.B. currently the code is not set up to actually record 
% responses from the participant, as this task is purely for attention].
% 
% As the duration of the tetra stimulus varies in length (8, 10 or 12 seconds)
% the participant must maintain attention for the second presentation of
% the task stimulus.  The actual response by the participant is irrelevant
% and is therefore not recorded - participants should be instructed that
% they wont receive any auditory feedback regarding their selections.
% 
% Input the experiment ID (ExptID), Participant Number (SubjectID) and the
% session number (SessionNum) to ensure data output is saved with correct
% particiant/session information.
%
% TODO - add in 'stimType' to the function to automatically create the
% desired directions, e.g. 'All' would create [0 1 0 0; 0 0 1 0; 1 1 1 1]
% whereas 'Mp' would create 0 1 0 0 only.  Would need to build in an if
% statement when building the parameters of the stim.
%
%
%
% Original code written by AW and LW 15 May 2013 ("ledtestblock_aw")
%
% 31 July 2013 - Edited by LW - added code to load FinalSetting files, 
%      and edited BaylorNomogram to use 4 cone peaks (parsed 'coneSensors' 
%      into nestled functions for easy editing of which cone peaks are used 
%      without changing every relevant function which uses it)
%
% 02 Aug 2013 - Edited by LW - added code to create Task Stimuli, and to
%      create the cues/prompts to go with the task.  Scan data built to
%      present the stimuli in the following order for each trial: cue, task1,
%      tetraStim, task2, prompt response.
%
% 07 Aug 2013 - Edited by LW - individual trials created for each component
%      of each trial sequence, to be loaded and run one by one in 
%      led_doScan_block_Task



% clear all existing variables except for the Session Details specified when
% running the function
clearvars -except ExptID SubjectID SessionNum 

% Load in a set of real calibration data obtained from our Prizmatix box
spectraAll=load('visibleLED_180713.mat');

% Open up the DAQ device and return a session object. This can take quite a
% a while...
session=pry_openSession(0:3,0,1); %(no. of channels, digitial, analogue)
disp(session.analogue.session); %display channels being used

% Set the output rate to 20KHz. This determines the precision of the PWM
session.analogue.session.Rate=20000;

% Specify the LEDs that are being used, and background values
dpy.maxValue=5; % Specific to the lightbox: the voltage we want to modulate around
dpy.spectra=spectraAll.linterp(:,[1 3 4 5]); %the LEDs we are using
dpy.spectra=dpy.spectra./(max(dpy.spectra(:)));
dpy.backRGB.dir=[1 1 1 1]*1; % the scale applied to the background LEDs. 
% I >think< that 1111 means they all have the same voltage out on them at the midpoint. 
dpy.backRGB.scale=0.5; % This sets the background intensity. Smaller values = darker backgrounds.

% Create Cone Spectra
coneSensors.wavelengths=400:2:700;
coneSensors.conepeaks=[576 555 534 442];
disp('using Baylor nomogram, for L Mprime M S')
dpy.coneSpectra=BaylorNomogram(coneSensors.wavelengths(:),coneSensors.conepeaks(:));
sensors=dpy.coneSpectra; % nWaves x mSensors

disp('*****Setting parameters and creating stimuli*****')


%% ***** Set the parameters of the Tetra stimuli *****

expt.stim.temporal.blockDurSecs=8:2:12; %Duration of stimulus presentation, secs
expt.preStimSecs=1; %Pre-stimulus pause before the start of the trials, secs

expt.stim.chrom.stimLMS.dir=[0 1 0 0]; %Mprime isolating 
expt.stim.temporal.freq=[1 4 8 12]; % frequency of flicker (Hz)
expt.stim.temporal.sampleRate=200; %this is the rate we sample the underlying waveform at.

%Create the contrasts using MaxContrast of the directions
nDirs=size(expt.stim.chrom.stimLMS.dir,1);
thisMaxContIndex=1;
for thisDir=1:nDirs
    stimLMS.dir=expt.stim.chrom.stimLMS.dir(thisDir,:);
    stimLMS.scale=0.04;
    [stimLMS stimRGB] = pry_findMaxSensorScale_Task(dpy,stimLMS,dpy.backRGB,sensors,coneSensors);
    maxCont(thisMaxContIndex)=stimLMS.maxScale;
    
    % this creates the contrasts that correspond to the directions
    expt.stim.chrom.stimLMS.scale(thisDir,:)=maxCont(thisMaxContIndex); 
    thisMaxContIndex=thisMaxContIndex+1;
end
MaxContrast=min(expt.stim.chrom.stimLMS.scale);
expt.stim.chrom.stimLMS.scale=[0.001:0.001:MaxContrast];

%% ***** Create the Tetra stimuli *****

nColours=size(expt.stim.chrom.stimLMS.dir,1);
nFreqs=length(expt.stim.temporal.freq);
nDurations=length(expt.stim.temporal.blockDurSecs);

% Loop over all colours, frequencies and durations, generating a single trial for each
% combination.
trialIndex=1;
for thisColour=1:nColours;
    for thisFreq=1:nFreqs;
        for thisDuration=1:nDurations;
            trial(trialIndex).stimulus.chrom.stimLMS.dir=expt.stim.chrom.stimLMS.dir(thisColour,:);
            trial(trialIndex).stimulus.chrom.stimLMS.cont=expt.stim.chrom.stimLMS.scale(thisColour);
            trial(trialIndex).stimulus.temporal.freq=expt.stim.temporal.freq(thisFreq);
            trial(trialIndex).stimulus.temporal.blockDurSecs=expt.stim.temporal.blockDurSecs(thisDuration);
            trial(trialIndex).stimulus.temporal.sampleRate=expt.stim.temporal.sampleRate;
            trialIndex=trialIndex+1;
        end %next duration
    end %next frequency
end %next colour

nTrials=trialIndex-1; % Number of different Tetra stimuli

%Shuffle the order of the trials
[trialData,trialOrder]=Shuffle(trial); 
trialData; %'trialData' (instead of 'trial') now contains the shuffled trials


%% ***** Set the parameters of the Task stimuli *****
% (used to maintain attention throughout a fMRI scan)
% Task stim only varies in freq, as task asks 'which is faster?'

expt.task.temporal.durationSecs=3;
expt.task.temporal.freq=1:1:nTrials; % we want same number of task stim as tetra stim
expt.task.temporal.sampleRate=200;
expt.task.chrom.stim.dir=[-1 0 0 1];

% create contrast using maxContrast for the given direction
nDirs=size(expt.task.chrom.stim.dir,1);
thisMaxContIndex=1;
for thisDir=1:nDirs
    stimLMS.dir=expt.task.chrom.stim.dir(thisDir,:);
    stimLMS.scale=0.04;
    [stimLMS stimRGB] = pry_findMaxSensorScale_Task(dpy,stimLMS,dpy.backRGB,sensors,coneSensors);
    maxCont(thisMaxContIndex)=stimLMS.maxScale;

    % this creates the contrasts that correspond to the directions
    expt.task.chrom.stim.scale(thisDir,:)=maxCont(thisMaxContIndex);        
    thisMaxContIndex=thisMaxContIndex+1;
end


%% ***** Create the Task stimuli *****

nTaskFreqs=length(expt.task.temporal.freq);
taskIndex=1;
%Loop over all frequencies to create the task stimuli
for taskFreq=1:nTaskFreqs;
    Task(taskFreq).stimulus.temporal.durationSecs=expt.task.temporal.durationSecs;
    Task(taskFreq).stimulus.temporal.freq=expt.task.temporal.freq(taskFreq);
    Task(taskFreq).stimulus.temporal.sampleRate=expt.task.temporal.sampleRate;
    Task(taskFreq).stimulus.chrom.dir=expt.task.chrom.stim.dir;
    Task(taskFreq).stimulus.chrom.scale=expt.task.chrom.stim.scale;
        taskIndex=taskIndex+1; 
end %next frequency
nTasks=taskIndex-1; % Number of task stimuli


[taskData,taskOrder]=Shuffle(Task); 
taskData; %taskData now contains the shuffled tasks



%% ***** Set the Parameters & Create the Cue stimuli *****
% The cue is presented before the start of the first Task stim.  As this
% will be the same stimulus for every cue, only one needs to be created.

dpy.cue.spectra=spectraAll.linterp(:,5); %the LEDs we are using
dpy.cue.spectra=dpy.cue.spectra./(max(dpy.cue.spectra(:)));
dpy.cue.backRGB.dir=1; % the scale applied to the background LEDs. 

expt.cue.temporal.durationSecs=2;
expt.cue.temporal.freq=1;
expt.cue.temporal.sampleRate=200;
expt.cue.chrom.stim.dir=[1 0 0 0];

%Create contrast using maxContrast for given direction
nDirs=size(expt.cue.chrom.stim.dir,1);
thisMaxContIndex=1;
for thisDir=1:nDirs
    stimLMS.dir=expt.cue.chrom.stim.dir(thisDir,:);
    stimLMS.scale=0.04;
    [stimLMS stimRGB] = pry_findMaxSensorScale_Task(dpy,stimLMS,dpy.backRGB,sensors,coneSensors);
    maxCont(thisMaxContIndex)=stimLMS.maxScale;

    % these are the contrasts that correspond to the the above directions
    expt.cue.chrom.stim.scale(thisDir,:)=maxCont(thisMaxContIndex); 
    thisMaxContIndex=thisMaxContIndex+1;
end


%% ***** Set the Parameters & Create the Prompt stimuli *****
% The prompt is presented after the second Task stim, to indicate the subject 
% should make a response to the 2IFC task. As this will be the same stimulus 
% for every prompt, only one needs to be created.

dpy.prompt.spectra=spectraAll.linterp(:,3); %the LEDs we are using
dpy.prompt.spectra=dpy.prompt.spectra./(max(dpy.prompt.spectra(:)));
dpy.prompt.backRGB.dir=1; % the scale applied to the background LEDs. 

expt.prompt.temporal.durationSecs=2;
expt.prompt.temporal.freq=1;
expt.prompt.temporal.sampleRate=200;
expt.prompt.chrom.stim.dir=[0 0 1 0];

%Create contrast using MaxContrast for given direction
nDirs=size(expt.prompt.chrom.stim.dir,1);
thisMaxContIndex=1;
for thisDir=1:nDirs
    stimLMS.dir=expt.prompt.chrom.stim.dir(thisDir,:);
    stimLMS.scale=0.04;
    [stimLMS stimRGB] = pry_findMaxSensorScale_Task(dpy,stimLMS,dpy.backRGB,sensors,coneSensors);
    maxCont(thisMaxContIndex)=stimLMS.maxScale;
    
    % these are the contrasts that correspond to the the above directions
    expt.prompt.chrom.stim.scale(thisDir,:)=maxCont(thisMaxContIndex); 
    thisMaxContIndex=thisMaxContIndex+1;
end

disp('Parameters set and Stimuli created')
 
%% ***** Create the sequence for each Full Trial *****
% A Full Trial is made up of: Cue > Task1 > Tetra Stim > Task2 > Prompt.
% This loop concatenates these stimuli in the correct order for each parameter, 
% and stores them in FullTrial.

disp('***Creating Trials***')
%create a random order of numbers 1 to nTrials, used in selecting the second presentation for the task stim
[randOrder]=Shuffle(1:nTrials); 

% Loop over the number of trials (i.e. total Tetra Stim that needs to be presented) 
% and concatenating stimuli for each parameter in the correct order they should be presented.
fullTrialsIndex=1;
for thistrial=1:nTrials;
    secondTask=randOrder(thistrial);
    FullTrial(thistrial).stimulus.temporal.duration=cat(1,expt.cue.temporal.durationSecs,...
        taskData(thistrial).stimulus.temporal.durationSecs, trialData(thistrial).stimulus.temporal.blockDurSecs,...
        taskData(secondTask).stimulus.temporal.durationSecs, expt.prompt.temporal.durationSecs);
    
    FullTrial(thistrial).stimulus.temporal.freq=cat(1,expt.cue.temporal.freq,...
        taskData(thistrial).stimulus.temporal.freq, trialData(thistrial).stimulus.temporal.freq,...
        taskData(secondTask).stimulus.temporal.freq, expt.prompt.temporal.freq);
    
    FullTrial(thistrial).stimulus.temporal.sampleRate=cat(1,expt.cue.temporal.sampleRate,...
        taskData(thistrial).stimulus.temporal.sampleRate, trialData(thistrial).stimulus.temporal.sampleRate,...
        taskData(secondTask).stimulus.temporal.sampleRate, expt.prompt.temporal.sampleRate);
    
    FullTrial(thistrial).stimulus.chrom.dir=cat(1,expt.cue.chrom.stim.dir,...
        taskData(thistrial).stimulus.chrom.dir, trialData(thistrial).stimulus.chrom.stimLMS.dir,...
        taskData(secondTask).stimulus.chrom.dir, expt.prompt.chrom.stim.dir);
    
    FullTrial(thistrial).stimulus.chrom.scale=cat(1,expt.cue.chrom.stim.scale,...
        taskData(thistrial).stimulus.chrom.scale, trialData(thistrial).stimulus.chrom.stimLMS.cont,...
        taskData(secondTask).stimulus.chrom.scale, expt.prompt.chrom.stim.scale);
    
    fullTrialsIndex=fullTrialsIndex+1;
    
end %next trial
nFullTrials=fullTrialsIndex-1;


%% ****** Create Onset times for each stimulus in each Full Trial ******

% Loop over the Full Trials and the stimuli in each, and set their onset times to be
% monotically increasing.
prevTimes=1;
for trialnumber=1:nFullTrials;
    for stimNumber=1:length(FullTrial(trialnumber).stimulus.temporal.duration);
        FullTrial(trialnumber).onsetTime(stimNumber,1)=expt.preStimSecs+(prevTimes-1);
        prevTimes=prevTimes+FullTrial(trialnumber).stimulus.temporal.duration(stimNumber,1);
    end
end


%% *** Split the stimuli from the Full Trials into their own Individual Trials ***
% Separate out the stimuli from of each Full Trial (Cue > Task1 > Tetra Stim > Task2 > Prompt)
% into their own trial, in order for them to be loaded and run one after
% the other.
% Number of individual trials = nFullTrials x nStimuliPerFullTrial


% Loop over the Full Trials and the Stimuli stored in each, to generate a single trial for
% each stimuli in order of onset time.
IndivTrial=1;
for TheFullTrial=1:nFullTrials;
    for TheStimuli=1:length(FullTrial(TheFullTrial).stimulus.temporal.duration);
        
        FinalTrials(IndivTrial).stimulus.temporal.duration=FullTrial(TheFullTrial).stimulus.temporal.duration(TheStimuli,:);
        FinalTrials(IndivTrial).stimulus.temporal.freq=FullTrial(TheFullTrial).stimulus.temporal.freq(TheStimuli,:);
        FinalTrials(IndivTrial).stimulus.temporal.sampleRate=FullTrial(TheFullTrial).stimulus.temporal.sampleRate(TheStimuli,:);
        FinalTrials(IndivTrial).stimulus.chrom.dir=FullTrial(TheFullTrial).stimulus.chrom.dir(TheStimuli,:);
        FinalTrials(IndivTrial).stimulus.chrom.scale=FullTrial(TheFullTrial).stimulus.chrom.scale(TheStimuli,:);
        FinalTrials(IndivTrial).onsetTime=FullTrial(TheFullTrial).onsetTime(TheStimuli,:);
        
        IndivTrial=IndivTrial+1;
    end %next Element
end %next Grouped Trial
nIndivTrials=IndivTrial-1; %number of individual trials

disp('Trials Created')


%%*********************************
scan.trials=FinalTrials; 


disp('******Waiting for Scanner. Press spacebar to continue******');

keypressed=0;
while(keypressed==0)
    [ch,w]=GetChar;
   keypressed=1;
end

disp('*****Running*****');
%Load and run the trials
status=led_doScan_block_Task(session,dpy,scan,coneSensors);


%Experiment Number, Subject Number and Session Number that were inputted
%when running the tetrachrom_block_Task function are now used to create the filename

filename=['TetraExpt',num2str(ExptID), '_ID', num2str(SubjectID),'_Session', num2str(SessionNum)];  %outputs filename as e.g. 'TetraExpt1_ID1_Session1'
% 
% %Save data in current folder
% 
save((filename))
% 
RunclosedSession=pry_closeSession(session);



