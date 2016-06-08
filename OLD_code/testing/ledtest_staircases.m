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

%% 
% Set the output rate to 20KHz. This determines the precision of the PWM
session.analogue.session.Rate=20000;


dpy.maxValue=5; % These values are specific to  the pkm device: they are the biggest voltage and the voltage we want to modulate around
dpy.baseValue=2.5;

dpy.spectra=spectraAll.linterp(:,[1 3 4 5]);
dpy.spectra=dpy.spectra./(max(dpy.spectra(:)));
dpy.backRGB.dir=[1 1 1 1]; % I think this is the scale applied to the background LEDs. I >think< that 1111 means they all have the same voltage out on them at the midpoint. 
dpy.backRGB.scale=0.25; % This sets the background intensity. Smaller values = darker backgrounds.


%Set the parameters of the trials

expt.blockDurSecs=2; %Duration of stimulus presentation, secs
expt.ISIsecs=1; %Inter stimulus interval, secs
expt.preStimSecs=0; %Pre-stimulus pause before the start of the trials, secs
expt.stim.chrom.stimLMS.dir=[0 0 1]; %This defines all the colour directions that we want to test (luminance, Scone isolation)
expt.stim.chrom.stimLMS.scale=[0.5]; % these are the contrasts that correspond to the the above directions
expt.stim.temporal.freq=[0:1:32]; % each of these frequencies will be applied to each of the colours, 0freq will create a control (off-) stim
expt.stim.chrom.noise.stimLMS.dir=[1 1 1];
expt.stim.chrom.noise.stimLMS.scale=0.03;
expt.stim.chrom.noise.type='white';
%expt.stim.chrom.noise.temporal=[10:20] %how do we apply random freq as
%noise?

stim.temporal.sampleRate=200; %this is the rate we sample the underlying wave form at. It is not the digitiser frequency.


%%%% should stim.temporal.freq be defined here? as it's already set above^^
%stim.temporal.freq=4; % Hz

stim.temporal.duration=expt.blockDurSecs; % s

nColours=size(expt.stim.chrom.stimLMS.dir,1);
nFreqs=length(expt.stim.temporal.freq);

%We have nColours by nFreqs different stimulus combinations

trialIndex=1;
% Loop over all colors and frequencies generating a single trial for each
% combinations.
for thisColour=1:nColours
    for thisFreq=1:nFreqs
        trials(trialIndex).stimulus=stim;
        trials(trialIndex).stimulus.chrom.stimLMS.dir=expt.stim.chrom.stimLMS.dir(thisColour,:);
        trials(trialIndex).stimulus.chrom.stimLMS.cont=expt.stim.chrom.stimLMS.scale(thisColour);
        trials(trialIndex).stimulus.temporal.freq=expt.stim.temporal.freq(thisFreq);
        trials(trialIndex).stimulus.noise=expt.stim.chrom.noise;
        %trial(trialIndex).onsetTime=(trialIndex-1)*(expt.blockDurSecs+expt.ISIsecs)+expt.preStimSecs
        trialIndex=trialIndex+1;
    end %next frequency
end %next colour


%create the settings to be used for the ISI - in this case luminance
%direction instead of sCone, so that it is clear when the first stimulus
%has stopped. Create as Trial 34 
expt.stim.chrom.stimLMS.dir=[1 1 1];
expt.stim.temporal.freq=[0];
trials(34).stimulus.chrom.stimLMS.dir=expt.stim.chrom.stimLMS.dir;
trials(34).stimulus.chrom.stimLMS.cont=expt.stim.chrom.stimLMS.scale;
trials(34).stimulus.temporal.freq=expt.stim.temporal.freq;
%trials(33).stimulus.noise=expt.stim.chrom.noise;


scan.trials=trials; 
session.analogue.session.Rate=20000;


%%**** Palamedes up/down adaptive method

%Set up up/down procedure:
UD.xCurrent=12; %trial number to start on

up = 1;                     %increase after 1 wrong
down = 3;                   %decrease after 3 consecutive right
StepSizeDown = 1;        
StepSizeUp = 1;
stopcriterion = 'trials';  % this can be 'trials' or 'reversals', staircase will terminate after the specified number of trials/reversals - given in 'stoprule' variable 
stoprule = 50;
startvalue = UD.xCurrent;           %intensity on first trial - in this case, determined by the trial number

TrialNumber=1;

UD = PAL_AMUD_setupUD('up',up,'down',down);
UD = PAL_AMUD_setupUD(UD,'StepSizeDown',StepSizeDown,'StepSizeUp', ...
    StepSizeUp,'stopcriterion',stopcriterion,'stoprule',stoprule, ...
    'startvalue',startvalue);

for nTrials=1:50
     
%Determine and display targeted proportion correct and stimulus intensity
%targetP = (StepSizeUp./(StepSizeUp+StepSizeDown)).^(1./down);
%message = sprintf('\rTargeted proportion correct: %6.4f',targetP);
%disp(message);
%targetX = scan.trials(UD.xCurrent).stimulus.temporal.freq;
%message = sprintf('Targeted stimulus intensity given simulated observer');
%message = strcat(message,sprintf(': %6.4f',targetX));
%disp(message);

%status=led_doScan(session,dpy,scan);
   dataExistFlag=0;
    if(isfield(scan.trials(UD.xCurrent).stimulus,'dacData'))
        if ~isempty(scan.trials(UD.xCurrent).stimulus.dacData)
            dataExistFlag=1;
        end
    end 
  if(~dataExistFlag)
        stim=pry_makeAnalogueStim(dpy,session,scan.trials(UD.xCurrent).stimulus);
        control=pry_makeAnalogueStim(dpy,session,scan.trials(1).stimulus);
        %ISI=pry_makeAnalogueStim(dpy,session,scan.trials(34).stimulus);
        convertToPWM=stim.LEDContrast+0.3; % The analogue stim runs around a mean of zero. which is wrong. Here we have to explicitly set the background so that the PWM can work...
        stim.dacData=pry_waveformToPWM(convertToPWM,scan.trials(UD.xCurrent).stimulus.temporal.sampleRate,session.analogue.session.Rate,100);
        control.dacData=pry_waveformToPWM(convertToPWM,scan.trials(1).stimulus.temporal.sampleRate,session.analogue.session.Rate,100);
        %ISI.dacData=pry_waveformToPWM(convertToPWM,scan.trials(34).stimulus.temporal.sampleRate,session.analogue.session.Rate,100);
  else
        % Assume that the stimulus.dacData is in place
        stim=scan.trials(UD.xCurrent).stimulus;
        control=scan.trials(1).stimulus;
        %ISI=scan.trials(34).stimulus;
  end

    
 vScale=5;
    stim.dacData=vScale-stim.dacData*vScale;
    stim.dacData(end,:)=4.5;
    control.dacData=vScale-control.dacData*vScale;
    control.dacData(end,:)=4.5;
    %ISI.dacData=vScale-ISI.dacData*vScale;
    %ISI.dacData(end,:)=4.5;
    
    
    stimOrderNum=rand;
    if stimOrderNum>=0.5
        presentationStim=cat(1,stim.dacData,control.dacData); %Stimulus is first presentation
        
        disp('Order: Stimulus, Control')
    elseif stimOrderNum<0.5
        
       presentationStim=cat(1,control.dacData,stim.dacData); %Stimulus is second presentation
        disp('Order: Control, Stimulus')
    end
    
    session.analogue.session.queueOutputData(presentationStim); 
    status=session.analogue.session.startForeground();
    
      
refTime = GetSecs;
timeoutTime=5;
disp('Respond')
KeyPress=2;

%Display the trial details
    [trialChrom]=trials(UD.xCurrent).stimulus.chrom.stimLMS.dir; %output the chrom direction of the trial
    [trialFreq]=trials(UD.xCurrent).stimulus.temporal.freq;
    disp(['Trial: ', num2str(UD.xCurrent)])
    disp(['      Stim Direction: ', num2str(trialChrom)])
    disp(['      Stim Frequency: ', num2str(trialFreq)])

while ~UD.stop && KeyPress==2
    [z,b,c]=KbCheck;
    if find(c)==98 & stimOrderNum<0.5  %Pressed key 2, and second presentation had the flicker
        KeyPress=0;
        disp('Correct choice')
        response = KeyPress;
        %UD = PAL_AMUD_updateUD(UD, response); %update UD structure
    elseif find(c)==98 & stimOrderNum>=0.5 %Pressed key 2, and first presentation had the flicker
        KeyPress=1;
        disp('Incorrect choice')
        response = KeyPress;
        %UD = PAL_AMUD_updateUD(UD, response); %update UD structure
    elseif find(c)==97 & stimOrderNum<0.5  %Pressed key 1, and second presentation had the flicker
        KeyPress=1;
        disp('Incorrect choice')
        response = KeyPress;
        %UD = PAL_AMUD_updateUD(UD, response); %update UD structure
    elseif find(c)==97 & stimOrderNum>=0.5 %Pressed key 1, and first presentation had the flicker
        KeyPress=0;
        disp('Correct choice')
        response = KeyPress;
        %UD = PAL_AMUD_updateUD(UD, response); %update UD structure
%     elseif GetSecs-refTime>=timeoutTime
%         disp('Time out')
    end
  
end
  UD = PAL_AMUD_updateUD(UD, response); %update UD structure
  
end
    
disp ('End of Session')




%Experiment number, Participant number and scan number that were inputted
%in the GUI should already be saved as variables in the workspace - these
%values are now used to create the filename
ExptID=1;
ScanNum=1;
SubjectID=1; %   Change these!

filename=['LEDExpt',num2str(ExptID), '_ID', num2str(SubjectID),'_Scan', num2str(ScanNum)];  %outputs filename as e.g. 'LEDExpt1_ID1_Scan1'

%Save data in the below folder (See the function 'fullfile')

save((filename))

closedSession=pry_closeSession(session);



