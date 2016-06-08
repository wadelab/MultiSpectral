clear all
close all
%function Exp_ledDUE_5LEDs
% Exp_ledDUE_5LEDs
% 
% Runs the experiment and prompts for subject ID, Experiment condition and
% session number.  Data is then saved out in the 'DATA' folder within:
% /Users/wadelab/Github_MultiSpectral/LEDarduino/Arduino_Project/
%
% File saved in the following format using the inputed session details:
%
% SubID001_Cond1_Freq1_Rep1_17-Feb-2015
%
% where the '001' and '1's are replaced with the relevant values for that
% repitition, subject and experiment condition and date.
%
%
% This version of the code incorporates the Quest algorithm from
% Psychtoolbox to estimate the detection threshold.
% Obviously, it needs PTB in the path.
% ARW 021515
% edited by LEW 170215 to be used with GUI and save out the contrast
% threshold obtained.

addpath(genpath('/Users/wadelab/Github_MultiSpectral'))
CONNECT_TO_ARDUINO = 1; % For testing on any computer
BITDEPTH=12; 
if(~isempty(instrfind))
   fclose(instrfind);
end

if (CONNECT_TO_ARDUINO)  
        system('say connecting to arduino');

    s=serial('/dev/tty.usbmodem5d11');%,'BaudRate',9600);
    fopen(s);
    disp('*** Connecting to Arduino');
    
else
    s=0;
end

%InitializePsychSound; % Initialize the Psychtoolbox sounds
pause(2);
fprintf('\n****** Experiment Running ******\n \n');
LEDamps=uint16([0,0,0,0,0]);
LEDbaseLevel=uint16(([35,90,65,150,90]/256)*(2^BITDEPTH)); % Adjust these to get a nice white background....THis is convenient and makes sure that everything is off by default
nLEDsTotal=length(LEDamps);


% This version of the code shows how to do two things:
% Ask Lauren's code for a set of LED amplitudes corresponding to a
% particula2r direction and contrast in LMS space
% 2: Present two flicker intervals with a random sequence
% ********************************************************

SubID=999;

experimentType=2; % Ask the user to enter a valid experiment type probing a particuar direction in LMS space


modulationRateHz=4; % Ask the user to enter a valid experiment type probing a particuar direction in LMS space


Repeat=1

ExpLabel={'LM','LMS','S'};
thisExp=ExpLabel{experimentType};



LEDsToUse=find(LEDbaseLevel);% Which LEDs we want to be active in this expt?
nLEDs=length(LEDsToUse);
% Iinitialize the display system
% Load LEDspectra calib contains 1 column with wavelengths, then the LED calibs
load('LEDspectra_070515.mat'); %load in calib for the prizmatix
LEDcalib=LEDspectra; %if update the file loaded, the name only has to be updated here for use in rest of code
LEDcalib(LEDcalib<0)=0;
clear LEDspectra
%resample to specified wavelength range (LEDspectra will now only contain
%the LED calibs, without the column for wavelengths)
dpy.WLrange=(390:2:720)'; %using range from 390 min because the stockman CFs range from 390 to 720+
dpy.bitDepth=BITDEPTH; % Bit depth of the output device. 8 for MEGA, 12 for Due. Make sure your Arduino code is synched!

spectrumIndex=0;
for thisLED=LEDsToUse
    spectrumIndex=spectrumIndex+1;
    LEDspectra(:,thisLED)=interp1(LEDcalib(:,1),LEDcalib(:,1+thisLED),dpy.WLrange);
end
LEDspectra(LEDspectra<0)=0;

%LEDspectra=LEDspectra-repmat(min(LEDspectra),size(LEDspectra,1),1);
%sumLED=sum(LEDspectra);
maxLED=max(LEDspectra);
LEDscale=1./maxLED;
%LEDscale=[128 128 128 128 128];

actualLEDScale=LEDscale./max(LEDscale);


dpy.LEDspectra=LEDspectra(:,LEDsToUse); %specify which LEDs to use out of the 7
dpy.LEDsToUse=LEDsToUse;
%dpy.backLED.dir=double(LEDbaseLevel(LEDsToUse))./max(double(LEDbaseLevel(LEDsToUse)))
dpy.backLED.dir=double(LEDbaseLevel)/double(max(LEDbaseLevel));

dpy.backLED.scale=.5;
dpy.LEDbaseLevel=round(dpy.backLED.dir*dpy.backLED.scale*(2.^dpy.bitDepth-1)); % Set just the LEDs we're using to be on a 50%
dpy.nLEDsTotal=nLEDsTotal;
dpy.nLEDsToUse=length(dpy.LEDsToUse);
dpy.modulationRateHz=modulationRateHz;

% Set up the parameters for the quest
% The thresholds for different opponent channels will be different. We
% estimate that they are .01 .02 and .1 for (L-M), L+M+S and s-(L+M)
% respectively (r/g, luminance, s-cone)

% Here we use the same variables that QuestDemo does for consistency

        stim.stimLMS.dir=[1 1 1]; % [1 1 1] is a pure achromatic luminance modulation
        tGuess=log10(.5);
        stim.stimLMS.maxLogCont=log10(.20);
  

tGuessSd=2; % This is roughly the same for all values.

% Print out what we are starting with:
fprintf('\nExpt %d - tGuess is %.2f, SD is %.2f\n',experimentType,tGuess,tGuessSd); % Those weird \n things mean 'new line'

pThreshold=0.82;
beta=3.5;delta=0.01;gamma=0.5;
q=QuestCreate(tGuess,tGuessSd,pThreshold,beta,delta,gamma);
q.normalizePdf=1; % This adds a few ms per call to QuestUpdate, but otherwise the pdf will underflow after about 1000 trials.

fprintf('Quest''s initial threshold estimate is %g +- %g\n',QuestMean(q),QuestSd(q));

% Run a series of trials. 
% On each trial we ask Quest to recommend an intensity and we call QuestUpdate to save the result in q.
trialsDesired=50;
wrongRight={'wrong','right'};
timeZero=GetSecs; % We >force< you to have PTB in the path for this so we know that GetSecs is present
 k=0; response=0;
 
dummyStim=stim;
system('say testing arduino');

for thisStim=.1:.2:1
disp(thisStim);

dummyStim.stimLMS.dir=[1 1 1];
dummyStim.stimLMS.scale=thisStim;
dummyResponse=led_doLEDTrial_5LEDs_16bit(dpy,dummyStim,q,s,1); % This should return 0 for an incorrect answer and 1 for correct

end





if (isobject(s)) % This is shorthand for ' if s>0 '
    % Shut down arduino to save the LEDs
      fwrite(s,zeros(5,1),'uint16'); % All writes to the Ardunio are now 16 bit unsigned ints. Even if the bit depth of the device is 8 (like a MEGA).
      fwrite(s,zeros(5,1),'uint16');
      fwrite(s,zeros(1,1),'uint16');
      
    fclose(s);
end
