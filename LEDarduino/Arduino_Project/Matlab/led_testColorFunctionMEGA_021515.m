% writeToSerial_modulation1SecPulse_012715_1
% This version of the code incorporates the Quest algorithm from
% Psychtoolbox to estimate the detection threshold.
% Obviously, it needs PTB in the path.
% ARW 021515
clear all;
close all;

addpath(genpath('/Users/wadelab/Github_MultiSpectral'))
CONNECT_TO_ARDUINO = 1; % For testing on any computer
if(~isempty(instrfind))
   fclose(instrfind);
end

if (CONNECT_TO_ARDUINO)  
        system('say connecting to arduino');

    s=serial('/dev/cu.usbmodem5d11');%,'BaudRate',9600);
    fopen(s);
    disp('*** Connecting to Arduino');
    
else
    s=0;
end

%InitializePsychSound; % Initialize the Psychtoolbox sounds
pause(2);
disp('Running');
LEDamps=uint8([0,0,0,0,0]);
LEDbaseLevel=uint8([128,128,0,128,128]); % Adjust these to get a nice white background....THis is convenient and makes sure that everything is off by default
nLEDsTotal=length(LEDamps);

% This version of the code shows how to do two things:
% Ask Lauren's code for a set of LED amplitudes corresponding to a
% particula2r direction and contrast in LMS space
% 2: Present two flicker intervals with a random sequence
% ********************************************************
experimentType=-1; % Ask the user to enter a valid experiment type probing a particuar direction in LMS space
while((experimentType<1) || (experimentType>3))
    experimentTypeS=input ('Experiment type (LM=1, LMS=2, S=3)?','s'); %=2;% 1=L-M, 2=(L+M+S), 3=S cone isolating
    experimentType=str2num(experimentTypeS);
    if(isempty(experimentType))
        experimentType=-1;
    end
    
    % *********************************************************
end

LEDsToUse=find(LEDbaseLevel);% Which LEDs we want to be active in this expt?
nLEDs=length(LEDsToUse);
% Iinitialize the display system
% Load LEDspectra calib contains 1 column with wavelengths, then the LED calibs
load('LEDspectra_16-Feb-2015.mat'); %load in calib for the prizmatix
LEDcalib=LEDspectra; %if update the file loaded, the name only has to be updated here for use in rest of code
clear LEDspectra
%resample to specified wavelength range (LEDspectra will now only contain
%the LED calibs, without the column for wavelengths)
dpy.WLrange=(380:2:720)';
for thisLED=1:size(LEDcalib,2)-1;
    LEDspectra(:,thisLED)=interp1(LEDcalib(:,1),LEDcalib(:,1+thisLED),dpy.WLrange);
end
%LEDspectra=LEDspectra-repmat(min(LEDspectra),size(LEDspectra,1),1);
%LEDspectra=LEDspectra./(repmat(max(LEDspectra),size(LEDspectra,1),1));

dpy.LEDspectra=LEDspectra(:,LEDsToUse); %specify which LEDs to use out of the 7
dpy.LEDsToUse=LEDsToUse;
dpy.bitDepth=8; % Can be 12 on new arduinos
dpy.backLED.dir=ones(nLEDs,1)';
dpy.backLED.scale=.5;
dpy.LEDamps=LEDamps; % DEfault levels
dpy.LEDbaseLevel=LEDbaseLevel; % Set just the LEDs we're using to be on a 50%
dpy.nLEDsTotal=nLEDsTotal;
dpy.nLEDsToUse=length(dpy.LEDsToUse);

% Set up the parameters for the quest
% The thresholds for different opponent channels will be different. We
% estimate that they are .01 .02 and .1 for (L-M), L+M+S and s-(L+M)
% respectively (r/g, luminance, s-cone)

% Here we use the same variables that QuestDemo does for consistency
switch experimentType % 1=L-M, 2=(L+M+S), 3=S cone isolating
    case 1    
        stim.stimLMS.dir=[.5 -1 0]; % [1 1 1] is a pure achroamtic luminance modulation
        tGuess=log10(.007); % Note - these numbers are log10 of the actual contrast. I'm making this explicit here.
        stim.stimLMS.maxLogCont= log10(.02);
        
    case 2
        stim.stimLMS.dir=[1 1 1]; % [1 1 1] is a pure achroamtic luminance modulation
        tGuess=log10(.02);
        stim.stimLMS.maxLogCont=log10(.95);
    case 3
        stim.stimLMS.dir=[0 0 1]; % [1 1 1] is a pure achroamtic luminance modulation
        tGuess=log10(.3);2
        stim.stimLMS.maxLogCont=log10(.6);
    otherwise
        error ('Incorrect experiment type');
end

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
trialsDesired=30;
wrongRight={'wrong','right'};
timeZero=GetSecs; % We >force< you to have PTB in the path for this so we know that GetSecs is present
 k=0; response=0;
 
dummyStim=stim;
system('say booting arduino');

dummyStim.stimLMS.dir=[1 1 1];
dummyStim.stimLMS.scale=.1;
dummyResponse=led_doLEDTrial(dpy,dummyStim,q,s,1); % This should return 0 for an incorrect answer and 1 for correct

system('say experiment beginning');

while ((k<trialsDesired) && (response ~= -1))
	% Get recommended level.  Choose your favorite algorithm.
	tTest=QuestQuantile(q);	% Recommended by Pelli (1987), and still our favorite.

	% We are free to test any intensity we like, not necessarily what Quest suggested.
	% 	tTest=min(-0.05,max(-3,tTest)); % Restrict to range of log contrasts that our equipment can produce.
    % ARW - Note: For the LMS threshold expts this is pretty important. We
    % will need to restrict tTest to the maximum contrast along each
    % direction
    % Roughly .06, .99 and .56 for L-M, L+M+S and S-(L+M) respectively
	
	% Run a trial - here we call a new function called 'led_doLEDTrial'
 
    timeSplit=GetSecs;
    
    %check whether the current tested value exceeds the max possible for
    %the given direction. If so, set to the max possible instead.
    if (tTest>stim.stimLMS.maxLogCont)
        tTest=stim.stimLMS.maxLogCont;
    end
    
    stim.stimLMS.scale=10^tTest; % Because it's log scaled
    
    response=led_doLEDTrial(dpy,stim,q,s); % This should return 0 for an incorrect answer and 1 for correct
    disp(response)
    
   	%response=QuestSimulate(q,tTest,tActual);
 	if (response ~=-1)
        fprintf('Trial %3d at %5.2f is %s\n',k,tTest,char(wrongRight(response+1)));
        timeZero=timeZero+GetSecs-timeSplit;
	
	% Update the pdf
        q=QuestUpdate(q,tTest,response); % Add the new datum (actual test intensity and observer response) to the database.
        k=k+1;
    else
        disp('Quitting...');
        system('say quitting before all trials complete');

    end
end

if (k == trialsDesired)
            system('say all trials complete');
end



if (isobject(s)) % This is shorthand for ' if s>0 '
    % Shut down arduino to save the LEDs
      fwrite(s,zeros(5,1),'uint8');
      fwrite(s,zeros(5,1),'uint8');
      
    fclose(s);
end

plot(q.intensity(1:q.trialCount));
t=QuestMean(q);		% Recommended by Pelli (1989) and King-Smith et al. (1994). Still our favorite.
sd=QuestSd(q);
fprintf('Final threshold estimate (mean+-sd) is %.2f +- %.2f\n',t,sd);
fprintf('Final threshold in actual contrast units is %.2f%%\n',10^(t)*100);
% TODO HERE - ADD IN AUTO SAVE FOR DATA...
