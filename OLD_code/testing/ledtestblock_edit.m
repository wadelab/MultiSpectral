% type RunExp into command window to open GUI 

clearvars -except ExptID SubjectID ScanNum %clear all existing variables except for the Session Details created with the GUI

% Load in a set of real calibration data obtained from our Prysmatix box
spectraAll=load('visibleLED.mat');
figure(1);
h=plot(400:2:700,spectraAll.linterp(:,[1 3 4 5]));

% this just colors the lines correctly in the plot
set(h(1),'Color',[0 0 1]);
set(h(2),'Color',[0 1 0]);
set(h(3),'Color',[1 0 0]);
set(h(4),'Color',[1 1 0]);

% Open up the DAQ device and return a session object. This can take quite a
% a while (10s)
session=pry_openSession(0:3,0,1);
disp(session.analogue.session);

%% Cell
% Set the output rate to 20KHz. This determines the precision of the PWM
session.analogue.session.Rate=20000;


dpy.maxValue=4.9; % These values are specific to  the pkm device: they are the biggest voltage and the voltage we want to modulate around
dpy.baseValue=2.5;

dpy.spectra=spectraAll.linterp(:,[1 3 4 5]);
dpy.spectra=dpy.spectra./(max(dpy.spectra(:)));
dpy.backRGB.dir=[1 1 1 1]; % I think this is the scale applied to the background LEDs. I >think< that 1111 means they all have the same voltage out on them at the midpoint. 
dpy.backRGB.scale=0.25; % This sets the background intensity. Smaller values = darker backgrounds.


%Set the parameters of the trials

expt.blockDurSecs=10; %Duration of stimulus presentation, secs
expt.ISIsecs=14; %Inter stimulus interval, secs
expt.preStimSecs=9; %Pre-stimulus pause before the start of the trials, secs
expt.stim.chrom.stimLMS.dir=[1 1 1;0 0 1]; %This defines all the colour directions that we want to test (luminance, Scone isolation)
expt.stim.chrom.stimLMS.scale=[0.05;0.5]; % these are the contrasts that correspond to the the above directions
expt.stim.temporal.freq=[0 4 8 16 32]; % each of these frequencies will be applied to each of the colours, 0freq will create a control (off-) stim


stim.temporal.sampleRate=200; %this is the rate we sample the underlying wave form at. It is not the digitiser frequency.

%%%% should stim.temporal.freq be defined here? as it's already set above^^
stim.temporal.freq=4; % Hz

stim.temporal.duration=expt.blockDurSecs; % s


nColours=size(expt.stim.chrom.stimLMS.dir,1);
nFreqs=length(expt.stim.temporal.freq);

%We have nColours by nFreqs different stimulus combinations, we will make
%trials that cover all of these combinations, and shuffle them before
%running

trialIndex=1;
% Loop over all colors and frequencies generating a single trial for each
% combinations.
for thisColour=1:nColours
    for thisFreq=1:nFreqs
        trial(trialIndex).stimulus=stim;
        trial(trialIndex).stimulus.chrom.stimLMS.dir=expt.stim.chrom.stimLMS.dir(thisColour,:);
        trial(trialIndex).stimulus.chrom.stimLMS.cont=expt.stim.chrom.stimLMS.scale(thisColour);
        trial(trialIndex).stimulus.temporal.freq=expt.stim.temporal.freq(thisFreq);
        %trial(trialIndex).onsetTime=(trialIndex-1)*(expt.blockDurSecs+expt.ISIsecs)+expt.preStimSecs
        trialIndex=trialIndex+1;
    end %next frequency
end %next colour

nTrials=trialIndex-1;

%Shuffle the order of the trials
[trialData,trialOrder]=Shuffle(trial);
trialOrder %output the trial order


trialindexonset=1;
% Here we loop over the (shuffled) trials and set their onset times to be
% monotically increasing.
for trialnumber=1:nTrials
    trialData(trialnumber).onsetTime=(trialindexonset-1)*(expt.blockDurSecs+expt.ISIsecs)+expt.preStimSecs;
    trialindexonset=trialindexonset+1;
end



scan.trials=trialData; %trialData is the shuffled trials
session.analogue.session.Rate=20000;
status=led_doScan(session,dpy,scan);



%Output details of each trial (the chrom direction and the frequency) in
%the same order that the trials were actually carried out
for theTrial=trialOrder 
    
    [trialChrom]=trial(theTrial).stimulus.chrom.stimLMS.dir; %output the chrom direction of the trial
    [trialFreq]=trial(theTrial).stimulus.temporal.freq; %output the Freq of the trail
      
    %Display the trial number and the Chrom and Freq values for that trial
    disp(['Trial: ', num2str(theTrial)])
    disp(['      Stim Direction: ', num2str(trialChrom)])
    disp(['      Stim Frequency: ', num2str(trialFreq)])
      
end

disp('Waiting for scanner to start');
pause(1);
keypressed=0;
while(keypressed==0)
    [ch,w]=GetChar;
   keypressed=1;
end

disp('Running*****');





wait(expt.ISIsecs)

disp ('End of Session')




%Experiment number, Participant number and scan number that were inputted
%in the GUI should already be saved as variables in the workspace - these
%values are now used to create the filename

filename=['LEDExpt',num2str(ExptID), '_ID', num2str(SubjectID),'_Scan', num2str(ScanNum)];  %outputs filename as e.g. 'LEDExpt1_ID1_Scan1'

%Save data in the below folder
cd 'C:\Users\WadeLab\Dropbox\WadelabWadeShare\Lightbox Stimulus\Data\'

save((filename))

closedSession=pry_closeSession(session);
clear all


