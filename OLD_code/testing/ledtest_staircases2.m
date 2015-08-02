% Runs a staircase to determine psychophysical thresholds for chromatic
% flicker
% 2IFC task: two trial are set up in a aingle scan and run. The doScan
% returns and the subject is then asked for a response.
% The staircase runs inside a loop. We use the palamides toolbox to get
% estimates22
%
clear all;
close all;


% Load in a set of real calibration data obtained from our Prysmatix box
disp('Loading spectra...');
spectraAll=load('visibleLED_053113');


% Open up the DAQ device and return a session object. This can take quite a
% a while (10s)
session=pry_openSession(0:3,0,1);
disp(session.analogue.session);

%%
% Set the output rate to 20KHz. This determines the precision of the PWM
session.analogue.session.Rate=20000;


dpy.maxValue=5; % These values are specific to  the pkm device: they are the biggest voltage and the voltage we want to modulate around
%dpy.baseValue=4;

dpy.spectra=spectraAll.linterp(:,[1 3 4 5]);
dpy.spectra=dpy.spectra./(max(dpy.spectra(:)));
dpy.backRGB.dir=[1 1 1 0.7] ; % I think this is the scale applied to the background LEDs. I >think< that 1111 means they all have the same voltage out on them at the midpoint.
dpy.backRGB.scale=0.5; % This sets the background intensity. Smaller values = darker backgrounds.

stock=load('stockmanData.mat'); % Load in stockman cone fundamentals resampled to an appropriate range...
dpy.coneSpectra=stock.stockmanData';

%Set the parameters of the trials

expt.blockDurSecs=0.5; %Duration of stimulus presentation, secs. In each trial we will have two stimulus presentations (1,2...)
expt.ISIsecs=0.5; %Inter stimulus interval, secs
expt.preStimSecs=0; %Pre-stimulus pause before the start of the trials, secs
expt.stim.chrom.stimLMS.dir=[0 0 1]; %T12122his defines all the colour directions that we want to test (luminance, Scone isolation)
expt.stim.chrom.stimLMS.scale=[0.1]; % This is the initial contrast. We increase it or decrease it as the staircase demands...
expt.stim.temporal.freq=[4]; % This is the frequency that we probe at....
expt.stim.chrom.noise.stimLMS.dir=[1 1 1];
expt.stim.chrom.noise.stimLMS.scale=0.1;
expt.stim.chrom.noise.type='white';
expt.stim.chrom.noise.temporal=[10:20] %how do we apply random freq as
% noise?

expt.stim.temporal.sampleRate=200; %this is the rate we sample the underlying wave form at. It is not the digitiser frequency.


expt.stim.temporal.duration=expt.blockDurSecs; % s

%We have nColours by nFreqs different stimulus combinations

trialIndex=1;
% Loop over all colors and frequencies generating a single trial for each
% combinations.
% Start the staircase.
% The variable 'contrast' is the thing that gets altered each time and then
% placed into the trials(trialIndex).stimulus.chrom.stimLMS.cont field
% Two trials are generated each time we loop: one with non-zero contrast,
% the other with zero contrast.
% At threshold, the subject is just barely able to discriminate these
% two...

%%**** Palamedes up/down adaptive method

%Set up up/down procedure:
UD.xCurrent=expt.stim.chrom.stimLMS.scale; % This is the initial contrast. We increase it or decrease it as the staircase demands... %Initial contrast level

up = 1;                     %increase after 1 wrong
down = 3;                   %decrease after 3 consecutive right
StepSizeDown = .001;
StepSizeUp = .001;
stopcriterion = 'trials';  % this can be 'trials' or 'reversals', staircase will terminate after the specified number of trials/reversals - given in 'stoprule' variable
stoprule = 50;
startvalue = UD.xCurrent;           %intensity on first trial - in this case, determined by the trial number

TrialNumber=1;

UD = PAL_AMUD_setupUD('up',up,'down',down);
UD = PAL_AMUD_setupUD(UD,'StepSizeDown',StepSizeDown,'StepSizeUp', ...
    StepSizeUp,'stopcriterion',stopcriterion,'stoprule',stoprule, ...
    'startvalue',startvalue);




for thisPresent=1:50
    fprintf('\nCurrent trial %d cont: %.3g',thisPresent,UD.xCurrent);
     ListenChar(2)
    randStimInterval=(rand(1)>0.5)+1;
    disp(randStimInterval)
    for trialIndex=1:2 % 2AFC
        trials(trialIndex).stimulus=expt.stim;
        trials(trialIndex).stimulus.chrom.stimLMS.dir=expt.stim.chrom.stimLMS.dir;
        trials(trialIndex).stimulus.chrom.stimLMS.cont=UD.xCurrent*(randStimInterval==trialIndex); %Initial contrast level
        trials(trialIndex).onsetTime=(trialIndex-1)*(expt.blockDurSecs+expt.ISIsecs)+1;
        
        trials(trialIndex).stimulus.temporal.freq=expt.stim.temporal.freq;
        % trials(trialIndex).stimulus.noise=expt.stim.chrom.noise;
    end % next trial
    
    %create the settings to be used for the ISI - in this case luminance
    %direction instead of sCone, so that it is clear when the first stimulus
    %has stopped. Create as Trial 34
    
    scan.trials=trials;
    beep;
    %sound(sin(linspace(0,2*pi*100,1000)));
    
    status=led_doScan(session,dpy,scan);
    
    %% Flush the input buffer, get a character
    FlushEvents;
    
    beep
    
    disp('Respond')
    
   
    KeyPress=GetChar;
    ListenChar(0)
    disp(KeyPress);
    
    
    %%
    
    
    if (randStimInterval==str2num(KeyPress))
        disp('Correct choice')
        
        UD = PAL_AMUD_updateUD(UD, 1); %update UD structure
    else
        disp('Incorrect choice')
        %UD = PAL_AMUD_updateUD(UD, response); %update UD structure
        
        
        UD = PAL_AMUD_updateUD(UD, 0); %update UD structure
    end
    
end % End of big presentation for loop
%% TODO: Replace that big conditional above with a single line
% Also - make sure you don't mirror output to the console.

disp ('End of Session')


plot(UD.xStaircase);





closedSession=pry_closeSession(session);



