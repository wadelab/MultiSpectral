function tetrachrom_block(ExptID,SubjectID,SessionNum)
% tetrachrom_block(ExptID,SubjectID,SessionNum)
% This function creates stimuli of particular directions and frequencies, 
% presented at varying contrast levels, to produce a block of stimuli 
% presented in a randomised order.
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
% Original code written by AW and LW 15 May 2013 ("ledtestblock_aw")
%
% Edited by LW on 31 July 2013 - added code to load FinalSetting files, 
% and edited BaylorNomogram to use 4 cone peaks (and parsed 'coneSensors' into 
% nestled functions for easy editing of which cone peaks are used without changing 
% every relevant function which uses it)



clearvars -except ExptID SubjectID SessionNum %clear all existing variables except for the Session Details created with the GUI

% Load in a set of real calibration data obtained from our Prysmatix box
spectraAll=load('visibleLED_180713.mat');

figure(1);
title('LED Spectra')
h=plot(400:2:700,spectraAll.linterp(:,[2 3 4 5])); 
%this just colors the lines correctly in the plot
set(h(1),'Color',[0 0 1]);
set(h(2),'Color',[0 1 0]);
set(h(3),'Color',[1 0.5 0]);
set(h(4),'Color',[1 0 0]);

% Open up the DAQ device and return a session object. This can take quite a
% a while (10s)
session=pry_openSession(0:3,0,1);
disp(session.analogue.session);

%% Cell
% Set the output rate to 20KHz. This determines the precision of the PWM
session.analogue.session.Rate=20000;
session.analogue.session.IsContinuous=false;

dpy.maxValue=5; % These values are specific to  the pkm device: they are the biggest voltage and the voltage we want to modulate around
dpy.spectra=spectraAll.linterp(:,[2 3 4 5]); %these are the LEDs we are using (i.e. excluding number 1 (410nm))
dpy.spectra=dpy.spectra./(max(dpy.spectra(:)));
dpy.backRGB.dir=[1 1 1 1]*1; %  this is the scale applied to the background LEDs. I >think< that 1111 means they all have the same voltage out on them at the midpoint. 
dpy.backRGB.scale=0.5; % This sets the background intensity. Smaller values = darker backgrounds.

%% Set the parameters of the trials
expt.blockDurSecs=5; %Duration of stimulus presentation, secs
expt.ISIsecs=2; %Inter stimulus interval, secs
expt.preStimSecs=1; %Pre-stimulus pause before the start of the trials, secs
expt.stim.chrom.stimLMS.dir=[0 0 1 0];
expt.stim.temporal.freq=2; % frequency of flicker (Hz)
expt.stim.chrom.stimLMS.scale=0.1;

stim.temporal.sampleRate=200; %this is the rate we sample the underlying wave form at. It is not the digitiser frequency.
stim.temporal.duration=expt.blockDurSecs; % s 

wavelengths=400:2:700;
conePeaks=[559 531 500 419];
%conePeaks=[570 542 442];

disp('using Adjusted Baylor nomogram, for L Mprime M S')
spectraData=pry_adjustedBaylor(wavelengths,conePeaks)


coneSensors.spectra=spectraData;

% 
% %Create max contrast value using maxContrast for the given direction
% nDirs=size(expt.stim.chrom.stimLMS.dir,1);
% thisMaxContIndex=1;
% for thisDir=1:nDirs
%     stimLMS.dir=expt.stim.chrom.stimLMS.dir(thisDir,:);
%     stimLMS.scale=0.05;
%     [stimLMS stimRGB] = pry_findMaxSensorScale(dpy,stimLMS,dpy.backRGB,sensors,coneSensors);
%     maxCont(thisMaxContIndex)=stimLMS.maxScale;
% 
%     % these are the contrasts that correspond to the the above directions
%     MaxContrast(thisDir,:)=maxCont(thisMaxContIndex); 
%     thisMaxContIndex=thisMaxContIndex+1;
% end
% 
% expt.stim.chrom.stimLMS.scale=(0.001:0.001:MaxContrast(1,:)); % the range of contrast upto the Max available for the M prime stim

%%
disp('*****Loading session*****')


nColours=size(expt.stim.chrom.stimLMS.dir,1);
nConts=length(expt.stim.chrom.stimLMS.scale);

%We have nColours by nFreqs different stimulus combinations, we will make
%trials that cover all of these combinations, and shuffle them before
%running

trialIndex=1;
% Loop over all colours and contrasts generating a single trial for each
% combination.
for thisColour=1:nColours;
    for thisCont=1:nConts;
        trial(trialIndex).stimulus=stim;
        trial(trialIndex).stimulus.chrom.stimLMS.dir=expt.stim.chrom.stimLMS.dir(thisColour,:);
        trial(trialIndex).stimulus.chrom.stimLMS.cont=expt.stim.chrom.stimLMS.scale(thisCont);
        trial(trialIndex).stimulus.temporal.freq=expt.stim.temporal.freq;
        trialIndex=trialIndex+1;
    end %next frequency
end %next colour

nTrials=trialIndex-1

%Shuffle the order of the trials
[trialData,trialOrder]=Shuffle(trial);

trialindexonset=1;
% Here we loop over the (shuffled) trials and set their onset times to be
% monotically increasing.
for trialnumber=1:nTrials
    trialData(trialnumber).onsetTime=(trialindexonset-1)*(expt.blockDurSecs+expt.ISIsecs)+expt.preStimSecs;
    trialindexonset=trialindexonset+1;
end

scan.trials=trialData; %trialData is the shuffled trials
session.analogue.session.Rate=20000;

% disp('Waiting for scanner to start');
% pause(1);
% keypressed=0;
% 
% while(keypressed==0)
%     [ch,w]=GetChar;
%    keypressed=1;
% end

disp('Running*****');

%Output details of each trial (the chrom direction and the frequency) in
%the same order that the trials were actually carried out
for theTrial=trialOrder 
    
    [trialChrom]=trial(theTrial).stimulus.chrom.stimLMS.dir; %output the chrom direction of the trial
    [trialCont]=trial(theTrial).stimulus.chrom.stimLMS.cont; %output the Freq of the trail
      
    %Display the trial number and the Chrom and Freq values for that trial
    disp(['Trial: ', num2str(theTrial)])
    disp(['      Stim Direction: ', num2str(trialChrom)])
    disp(['      Stim Contrast:  ', num2str(trialCont)])
      
end

status=led_doScan_block(session,dpy,scan,expt,coneSensors);



disp ('End of Session')




%Experiment number, Stimulus Code, Participant number and session number that were inputted
%in the GUI should be saved as variables in the workspace - these
%values are now used to create the filename

filename=['TetraExpt',num2str(ExptID), '_ID', num2str(SubjectID),'_Session', num2str(SessionNum)];  %outputs filename as e.g. 'LEDExpt1_ID1_Scan1'
% 
% %Save data in current folder
% 
save((filename))
% 
RunclosedSession=pry_closeSession(session);



