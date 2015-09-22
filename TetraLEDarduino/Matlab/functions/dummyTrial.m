% run a single dummyTrial to turn LEDs on (to use as fixation before stim
% starts.  Details copied from Run_TetraExp_DUE_5LEDs.m

BITDEPTH=12;
LEDamps=uint16([0,0,0,0,0]);
nLEDsTotal=length(LEDamps);

load('LEDspectra_070515.mat'); %load in calib for the prizmatix
LEDcalib=LEDspectra; %if update the file loaded, the name only has to be updated here for use in rest of code
LEDcalib(LEDcalib<0)=0;
clear LEDspectra

dpy.WLrange=(400:1:720)'; %must use range from 400 to 720 

% use white spectra to get baselevels for each LED (so white light as
% background), and resample the LEDcalib spectra to the desired WL range

[baselevels, LEDspectra] = LED2white(LEDcalib,dpy); % send the LED spectra and dpy with WL values
baselevelsLEDS=baselevels/2; %we want them at half their scaled levels
LEDbaseLevel=uint16((baselevelsLEDS)*(2^BITDEPTH)); % Adjust these to get a nice white background....THis is convenient and makes sure that everything is off by default
fprintf('Baselevels:\n%d\n',baselevelsLEDS);
fprintf('converted baselevels:\n%d\n',LEDbaseLevel);

LEDsToUse=find(LEDbaseLevel);% Which LEDs we want to be active in this expt?

dpy.baselevelsLEDS=baselevelsLEDS;

dpy.bitDepth=BITDEPTH;
dpy.LprimePosition=0.5; %default position of the Lprime peak in relation to L and M cone peaks: 0.5 is half way between, 0 is M cone and 1 is L cone

dpy.Freq=4;
    
dpy.LEDspectra=LEDspectra(:,LEDsToUse); %specify which LEDs to use
dpy.LEDsToUse=LEDsToUse;
dpy.backLED.dir=baselevelsLEDS;

dpy.backLED.scale=.5;
dpy.LEDbaseLevel=round(dpy.backLED.dir*dpy.backLED.scale*(2.^dpy.bitDepth-1)); % Set just the LEDs we're using to be on a 50%
dpy.nLEDsTotal=nLEDsTotal;
dpy.nLEDsToUse=length(dpy.LEDsToUse);
dpy.modulationRateHz=dpy.Freq;

tGuess=log10(.02);

tGuessSd=2; % This is roughly the same for all values.

pThreshold=0.82;
beta=3.5;delta=0.01;gamma=0.5;
q=QuestCreate(tGuess,tGuessSd,pThreshold,beta,delta,gamma);
q.normalizePdf=1; % This adds a few ms per call to QuestUpdate, but otherwise the pdf will underflow after about 1000 trials.


Speak('Preparing experiment','Daniel');
dpy.NumSpec=3;
dummyStim.stimLMS.dir=[1 1 1];
dummyStim.stimLMS.scale=.1;
[dummyResponse,dpy]=tetra_led_doLEDTrial_5LEDs(dpy,dummyStim,q,s,1); % This should return 0 for an incorrect answer and 1 for correct

