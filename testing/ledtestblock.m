% type RunExp into command window to open GUI 

clearvars -except ExptID SubjectID ScanNum %clear all existing variables except for the Session Details created with the GUI

% Load in a set of real calibration data obtained from our Prysmatix box
spectraAll=load('visibleLED.mat');
figure(1);
h=plot(400:2:700,spectraAll.linterp(:,[1 3 4 5]));
set(h(1),'Color',[0 0 1]);
set(h(2),'Color',[0 1 0]);
set(h(3),'Color',[1 0 0]);
set(h(4),'Color',[1 1 0]);

session=pry_openSession(0:3,0,1);
disp(session.analogue.session);

%%
session.analogue.session.Rate=20000;


dpy.maxValue=4.9; % These values are specific to  the pkm device: they are the biggest voltage and the voltage we want to modulate around
dpy.baseValue=2.5;

dpy.spectra=spectraAll.linterp(:,[1 3 4 5]);
dpy.spectra=dpy.spectra./(max(dpy.spectra(:)));
dpy.backRGB.dir=[1 1 1 1];
dpy.backRGB.scale=0.25;


%Set the parameters of the trials

expt.blockDurSecs=10; %Duration of stimulus presentation, secs
expt.ISIsecs=14; %Inter stimulus interval, secs
expt.preStimSecs=9; %Pre-stimulus pause before the start of the trials, secs
expt.stim.chrom.stimLMS.dir=[1 1 1]; %This defines all the colour directions that we want to test (luminance, Scone isolation)
expt.stim.chrom.stimLMS.scale=[0.5]; % these are the contrasts that correspond to the the above directions
expt.stim.temporal.freq=[4 8]; % each of these frequencies will be applied to each of the colours, 0freq will create a control (off-) stim

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


%Shuffle the order of the trials
[trialData,trialOrder]=Shuffle(trial);
trialOrder %output the trial order


trialindexonset=1;
for trialnumber=trialOrder
    trialData(trialnumber).onsetTime=(trialindexonset-1)*(expt.blockDurSecs+expt.ISIsecs)+expt.preStimSecs;
    trialindexonset=trialindexonset+1;
end



scan.trials=trialData; %trialData is the shuffled trials
session.analogue.session.Rate=20000;
%status=led_doScan(session,dpy,scan);



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


nTrials=length(scan.trials);
scanStartTime=GetSecs; % This is the current time in seconds when the scan starts. All the other elapsed times will be referenced off this.


trialstring=1;
for thisTrial=trialOrder;    %stim.trialOrder(trialstring)
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
        stim=pry_makeAnalogueStim(dpy,session,scan.trials(thisTrial).stimulus);
        
        convertToPWM=stim.LEDContrast.*0.5+0.75; % ********* CHECK THIS!!!!
        stim.dacData=pry_waveformToPWM(convertToPWM,scan.trials(thisTrial).stimulus.temporal.sampleRate,session.analogue.session.Rate,100);
    else
        % Assume that the stimulus.dacData is in place
        stim=scan.trials(thisTrial).stimulus;
    end
    
    
    %Load the data onto the dac
    vScale=6;
    stim.dacData=vScale-stim.dacData*vScale;
    stim.dacData(end,:)=4.5;
    session.analogue.session.queueOutputData(double(stim.dacData));
   
    % Here we enter a loop - wait until the current time is >= the trial
    % onset time
  
    while ((GetSecs-scanStartTime)<scan.trials(thisTrial).onsetTime) %
        % Do nothing
    end
    status=session.analogue.session.startForeground();
end % Go to the next trial


%wait(expt.ISIsecs)

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


