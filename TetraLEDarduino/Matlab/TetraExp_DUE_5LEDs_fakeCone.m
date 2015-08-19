clear all
close all
%function TetraExp_DUE_5LEDs
% TetraExp_DUE_5LEDs
% 
% Runs the experiment and prompts for subject ID, Experiment condition and
% session number.  Data is then saved out in the 'DATA' folder within:
% /Users/wadelab/Github_MultiSpectral/TetraLEDarduino/Data_tetraStim
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
% Now edited to work at 16bit

addpath(genpath('/Users/wadelab/Github_MultiSpectral/TetraLEDarduino'))
CONNECT_TO_ARDUINO = 1; % For testing on any computer
BITDEPTH=12;
if(~isempty(instrfind))
   fclose(instrfind);
end

if (CONNECT_TO_ARDUINO)  
        system('say connecting to arduino');

    s=serial('/dev/tty.usbmodem5d11');%,'BaudRate',9600);q
    fopen(s);
    disp('*** Connecting to Arduino');
    
else
    s=0;
end

%InitializePsychSound; % Initialize the Psychtoolbox sounds
pause(2);
fprintf('\n****** Experiment Running ******\n \n');
LEDamps=uint16([0,0,0,0,0]);
LEDbaseLevel=uint16(([.125,0.5,0.17,0.47,0.39])*(2^BITDEPTH)); % Adjust these to get a nice white background....THis is convenient and makes sure that everything is off by default
nLEDsTotal=length(LEDamps);

system('say Enter experiment parameters');
% This version of the code shows how to do two things:
% Ask Lauren's code for a set of LED amplitudes corresponding to a
% particular direction and contrast in LMS space
% 2: Present two flicker intervals with a random sequence
% ********************************************************

SubID=-1; % Ask the user to enter a Subject ID number
while(SubID<1)
    SubID=input ('Enter Subject ID, e.g. 001: ','s'); %prompts to enter a subject ID
    if(isempty(SubID))
        SubID=-1;
    end
    
    % ***** ****************************************************
end

experimentType=-1; % Ask the user to enter a valid experiment type probing a particuar direction in LMS space
while((experimentType<1) || (experimentType>3))
    experimentTypeS=input ('Experiment condition code (L, M, MS, S, LMS, LM): ','s'); %
    experimentTypeS=upper(experimentTypeS);
    %experimentType=str2num(experimentTypeS);
    if(isempty(experimentTypeS))
        experimentType=-1;
    else experimentType=1;
    end
    
    % *********************************************************
end

modulationRateHz=-1; % Ask the user to enter a valid experiment type probing a particuar direction in LMS space
while((modulationRateHz<0) || (modulationRateHz>65))
    modulationRateHzString=input ('Frequency in Hz e.g. 0.5, 1, 2, 4, etc: ','s'); %enter the Hz for exp
    modulationRateHz=str2num(modulationRateHzString);
    if(isempty(modulationRateHz))
        modulationRateHz=-1;
    end
    
    % *********************************************************
end

Repeat=-1; % Ask the user to enter a session number
while(Repeat<1)
    RepeatString=input ('Enter the session number for this condition: ','s'); %=2;% 1=L-M, 2=(L+M+S), 3=S cone isolating
    Repeat=str2num(RepeatString);
    if(isempty(Repeat))
        Repeat=-1;
    end
    
    % *********************************************************
end
tic
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
dpy.WLrange=(400:1:720)'; %must use range from 400 to 720 
dpy.bitDepth=BITDEPTH;
dpy.noiseLevel=1; %amount of noise to add to intervals - added to the direction of stim, so [1 0 0 0] becomes [1.1 .1 .1 .1]
dpy.noiseScale=0.0;
dpy.LprimePosition=0.5; %position of the Lprime peak in relation to L and M cone peaks: 0.5 is half way between, 0 is M cone and 1 is L cone
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


% ********** this isn't currently used anywhere else... should it be?!
actualLEDScale=LEDscale./max(LEDscale);


dpy.LEDspectra=LEDspectra(:,LEDsToUse); %specify which LEDs to use
dpy.LEDsToUse=LEDsToUse;
%dpy.bitDepth=8; % Can be 12 on new arduinos
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
switch experimentTypeS % 1=L-M, 2=(L+M+S), 3=S cone isolating
    case {'L','l'}  
        stim.stimLMS.dir=[1 0 0 0]; % L cone isolating
        tGuess=log10(.005); % Note - these numbers are log10 of the actual contrast. I'm making this explicit here.
        stim.stimLMS.maxLogCont= log10(.008);
        thisExp='L';
        
    case {'M','m'}    
        stim.stimLMS.dir=[0 1 0 0]; % M cone isolating
        tGuess=log10(.005); % Note - these numbers are log10 of the actual contrast. I'm making this explicit here.
        stim.stimLMS.maxLogCont= log10(.008);
        thisExp='M';
        
    case {'MS','ms'}    
        stim.stimLMS.dir=[0 0 1 0]; % M cone isolating
        tGuess=log10(.005); % Note - these numbers are log10 of the actual contrast. I'm making this explicit here.
        stim.stimLMS.maxLogCont= log10(.008);
        thisExp='MS';
        
    case {'LM','lm'}    
        stim.stimLMS.dir=[.5 -1 0 0]; % L-M isolating
        tGuess=log10(.01); % Note - these numbers are log10 of the actual contrast. I'm making this explicit here.
        stim.stimLMS.maxLogCont= log10(.015);
        thisExp='LM';
    

    case {'LMS','lms'}
        stim.stimLMS.dir=[1 1 1 1]; % [1 1 1] is a pure achromatic luminance modulation
        tGuess=log10(.005);
        stim.stimLMS.maxLogCont=log10(.008);
        thisExp='LMS';
        
    case {'S','s'}
        stim.stimLMS.dir=[0 0 0 1]; % S cone isolating
        tGuess=log10(.4);
        stim.stimLMS.maxLogCont=log10(.45);
        thisExp='S';
        
    otherwise
        error ('Incorrect experiment type');
end

tGuessSd=2; % This is roughly the same for all values.

% Print out what we are starting with:
fprintf('\nExpt %s - tGuess is %.2f, SD is %.2f\n',thisExp,tGuess,tGuessSd); % Those weird \n things mean 'new line'

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
system('say booting arduino');

dummyStim.stimLMS.dir=[1 1 1 1];
dummyStim.stimLMS.scale=.1;
dummyResponse=tetra_led_doLEDTrial_5LEDs_fakeCone(dpy,dummyStim,q,s,1); % This should return 0 for an incorrect answer and 1 for correct

%prompt to press 1 to start
toStart=-1;
pause(1);
system('say Press 1 to start')
while(toStart<0)    
    startString=GetChar; %awaiting 1
    toStart=str2double(startString);
    if(isempty(Repeat))
        toStart=-1;
    end
    disp(toStart)
    
    % *********************************************************
end
    
system('say Experiment beginning');

while ((k<trialsDesired) && (response ~= -1))
	% Get recommended level.  Choose your favorite algorithm.
	tTest=QuestQuantile(q);	% Recommended by Pelli (1987), and still our favorite.

	% We are free to test any intensity we like, not necessarily what Quest suggested.
	% 	tTest=min(-0.05,max(-3,tTest)); % Restrict to range of log contrasts that our equipment can produce.
    % ARW - Note: For the LMS threshold expts this is pretty important. We
    % will need to restrict tTest to the maximum contrast along each
    % direction
    % Roughly .06, .99 and .56 for L-M, L+M+S and S-(L+M) respectively
	
	% Run a trial - here we call a new function called 'led_doLEDTrial_5LEDs'
 
    timeSplit=GetSecs;
    
    %check whether the current tested value exceeds the max possible for
    %the given direction. If so, set to the max possible instead.
    if (tTest>stim.stimLMS.maxLogCont)
        tTest=stim.stimLMS.maxLogCont;
    end
    
    stim.stimLMS.scale=10^tTest; % Because it's log scaled
    
    response=tetra_led_doLEDTrial_5LEDs_fakeCone(dpy,stim,q,s); % This should return 0 for an incorrect answer and 1 for correct
    %disp(response)
    
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
      fwrite(s,zeros(5,1),'uint16');
      fwrite(s,zeros(5,1),'int8');
      fwrite(s,zeros(5,1),'uint16');
      fwrite(s,zeros(2,1),'uint16');
      disp('Turning off LEDs');
%       pause(0.5)
      fclose(s);
end
figure()
plot(q.intensity(1:q.trialCount));
Data.qInfo=q;
Data.qIntensity(1:q.trialCount,1)=q.intensity(1:q.trialCount)'; %save out the intensity estimates (log(contrast) per trial)
title(sprintf('%s cone at %.1f Hz Trial %d',thisExp,modulationRateHz,Repeat))
t=QuestMean(q);		% Recommended by Pelli (1989) and King-Smith et al. (1994). Still our favorite.
sd=QuestSd(q);
contrastThresh=10^(t)*100;
contrastStDevPos=(10^(t)*100)-(10^(t-sd)*100);
contrastStDevNeg=(10^(t+sd)*100)-(10^(t)*100);
fprintf('Experiment Condition: %s Freq: %.1f\n',thisExp,modulationRateHz);
fprintf('Final threshold estimate (mean+-sd) is %.2f +- %.2f\n',t,sd);
fprintf('Final threshold in actual contrast units is %.2f%% SD is + %.2f%% -%.2f%%\n',contrastThresh,contrastStDevPos,contrastStDevNeg);
% TODO HERE - ADD IN AUTO SAVE FOR DATA...

%cd to the data folder
Date=datestr(now,30); %current date with time

cd('/Users/wadelab/Github_MultiSpectral/TetraLEDarduino/Data_tetraStim')

Data.rawThresh=t;
Data.rawStDev=sd;
Data.contrastThresh=contrastThresh;
Data.contrastStDevPos=contrastStDevPos;
Data.contrastStDevNeg=contrastStDevNeg;
Data.SubID=SubID;
Data.thisExp=thisExp;
Data.modulationRateHz=modulationRateHz;
Data.Repeat=Repeat;
Data.Date=Date;

%save out a file containing the contrastThresh, SubID, experimentType, freq and
%Session num

save(sprintf('SubID%s_Cond%s_Freq%.1f_Rep%d_%s.mat',...
    SubID,thisExp,modulationRateHz,Repeat,Date),'Data');

%save figure
savefig(sprintf('SubID%s_Cond%s_Freq%.1f_Rep%d_%s.fig',...
    SubID,thisExp,modulationRateHz,Repeat,Date));
fprintf('\nSubject %s data saved\n',SubID);
fprintf('\n******** End of Experiment ********\n');


timeElapsed=toc/60;
fprintf('Experiment complete in %.3f minutes\n',timeElapsed);
