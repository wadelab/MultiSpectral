function Data=Run_TetraExp_DUE_5LEDs(dpy,s)
% Run_TetraExp_DUE_5LEDs(dpy)
%
% Runs the experiment using details from dpy. s is the serial connection.
%
% dpy should contain:
% dpy.SubID     = the SubjectID 
% dpy.NumSpec   = the number of cone spectra to use, either 2 3 or 4
% dpy.ExptID    = the experiment ID
% dpy.Repeat    = which session number is it
% dpy.Freq      = the frequency (Hz) of the stimulus  
% 
% Outputs 'Data', containing final thresholds, etc. 
%
%
% This version of the code incorporates the Quest algorithm from
% Psychtoolbox to estimate the detection threshold.
% Obviously, it needs PTB in the path.
% ARW 021515
% edited by LEW 200815 as a function to output 'Data'

addpath(genpath('/Users/wadelab/Github_MultiSpectral/TetraLEDarduino'))

%InitializePsychSound; % Initialize the Psychtoolbox sounds
pause(2);
fprintf('\n****** Experiment Running ******\n \n');
BITDEPTH=12;
LEDamps=uint16([0,0,0,0,0]);
nLEDsTotal=length(LEDamps);
% This version of the code shows how to do two things:
% Ask Lauren's code for a set of LED amplitudes corresponding to a
% particular direction and contrast in LMS space
% 2: Present two flicker intervals with a random sequence
% ********************************************************



% Iinitialize the display system
% Load LEDspectra calib contains 1 column with wavelengths, then the LED calibs
load('LEDspectra_070515.mat'); %load in calib for the prizmatix
LEDcalib=LEDspectra; %if update the file loaded, the name only has to be updated here for use in rest of code
LEDcalib(LEDcalib<0)=0;
clear LEDspectra

dpy.WLrange=(400:1:720)'; %must use range from 400 to 720 

% use illuminant C to get baselevels for each LED (so white light as
% background), and resample the LEDcalib spectra to the desired WL range

[baselevels, LEDspectra] = LED2illumC(LEDcalib,dpy); % send the LED spectra and dpy with WL values
baselevelsLEDS=baselevels/2; %we want them at half their scaled levels
LEDbaseLevel=uint16((baselevelsLEDS)*(2^BITDEPTH)); % Adjust these to get a nice white background....THis is convenient and makes sure that everything is off by default


LEDsToUse=find(LEDbaseLevel);% Which LEDs we want to be active in this expt?

dpy.baselevelsLEDS=baselevelsLEDS;

dpy.bitDepth=BITDEPTH;
dpy.LprimePosition=0.5; %position of the Lprime peak in relation to L and M cone peaks: 0.5 is half way between, 0 is M cone and 1 is L cone



dpy.LEDspectra=LEDspectra(:,LEDsToUse); %specify which LEDs to use
dpy.LEDsToUse=LEDsToUse;
dpy.backLED.dir=baselevelsLEDS;

dpy.backLED.scale=.5;
dpy.LEDbaseLevel=round(dpy.backLED.dir*dpy.backLED.scale*(2.^dpy.bitDepth-1)); % Set just the LEDs we're using to be on a 50%
dpy.nLEDsTotal=nLEDsTotal;
dpy.nLEDsToUse=length(dpy.LEDsToUse);
dpy.modulationRateHz=dpy.Freq;

% Set up the parameters for the quest
% The thresholds for different opponent channels will be different. We
% estimate that they are .01 .02 and .1 for (L-M), L+M+S and s-(L+M)
% respectively (r/g, luminance, s-cone)


% Here we use the same variables that QuestDemo does for consistency
switch dpy.ExptID 
    case {'L'}  
        if dpy.NumSpec==4
        stim.stimLMS.dir=[1 0 0 0]; % L cone isolating
        tGuess=log10(.005); % Note - these numbers are log10 of the actual contrast. I'm making this explicit here.
        stim.stimLMS.maxLogCont= log10(.008);        
        elseif dpy.NumSpec==3
        stim.stimLMS.dir=[1 0 0]; % L cone isolating
        tGuess=log10(.04); % Note - these numbers are log10 of the actual contrast. I'm making this explicit here.
        stim.stimLMS.maxLogCont= log10(.05);
        end
        thisExp='L';
        
    case {'LP'}  
        stim.stimLMS.dir=[0 1 0 0]; % L cone isolating
        tGuess=log10(.005); % Note - these numbers are log10 of the actual contrast. I'm making this explicit here.
        stim.stimLMS.maxLogCont= log10(.008);
        thisExp='Lp';
    
    case {'M'}    
        if dpy.NumSpec==4
        stim.stimLMS.dir=[0 0 1 0]; % L cone isolating
        tGuess=log10(.005); % Note - these numbers are log10 of the actual contrast. I'm making this explicit here.
        stim.stimLMS.maxLogCont= log10(.008);        
        elseif dpy.NumSpec==3
        stim.stimLMS.dir=[0 1 0]; % L cone isolating
        tGuess=log10(.04); % Note - these numbers are log10 of the actual contrast. I'm making this explicit here.
        stim.stimLMS.maxLogCont= log10(.05);
        end
        thisExp='M';
        
    case {'LM'}    
        if dpy.NumSpec==4
        stim.stimLMS.dir=[0.5 0 -1 0]; % L cone isolating
        tGuess=log10(.01); % Note - these numbers are log10 of the actual contrast. I'm making this explicit here.
        stim.stimLMS.maxLogCont= log10(.015);        
        elseif dpy.NumSpec==3
        stim.stimLMS.dir=[0.5 -1 0]; % L cone isolating
        tGuess=log10(.04); % Note - these numbers are log10 of the actual contrast. I'm making this explicit here.
        stim.stimLMS.maxLogCont= log10(.05);
        end;
        thisExp='LM';
        
    case {'LMS'}
        if dpy.NumSpec==4
        stim.stimLMS.dir=[1 1 1 1]; % L cone isolating
        tGuess=log10(.008); % Note - these numbers are log10 of the actual contrast. I'm making this explicit here.
        stim.stimLMS.maxLogCont= log10(.02);        
        elseif dpy.NumSpec==3
        stim.stimLMS.dir=[1 1 1]; % L cone isolating
        tGuess=log10(.01); % Note - these numbers are log10 of the actual contrast. I'm making this explicit here.
        stim.stimLMS.maxLogCont= log10(.05);
        end
        thisExp='LMS';
        
    case {'S'}
        if dpy.NumSpec==4
        stim.stimLMS.dir=[0 0 0 1]; % L cone isolating
        tGuess=log10(.4); % Note - these numbers are log10 of the actual contrast. I'm making this explicit here.
        stim.stimLMS.maxLogCont= log10(.45);        
        elseif dpy.NumSpec==3
        stim.stimLMS.dir=[0 0 1]; % L cone isolating
        tGuess=log10(.4); % Note - these numbers are log10 of the actual contrast. I'm making this explicit here.
        stim.stimLMS.maxLogCont= log10(.45);
        elseif dpy.NumSpec==2
        stim.stimLMS.dir=[0 1]; % L cone isolating
        tGuess=log10(.4); % Note - these numbers are log10 of the actual contrast. I'm making this explicit here.
        stim.stimLMS.maxLogCont= log10(.45);
        end
        thisExp='S';
        
    case {'TESTLM'}
        if dpy.NumSpec==2
        stim.stimLMS.dir=[1 0]; % testLM cone isolating
        tGuess=log10(.04); % Note - these numbers are log10 of the actual contrast. I'm making this explicit here.
        stim.stimLMS.maxLogCont= log10(.08);   
        else
            error('Incorrect NumSpec for this condition')
        end
        thisExp='testLM';
        
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
try
    trialsDesired=dpy.NumTrials;
catch
trialsDesired=50; %default 50 trials
end
wrongRight={'wrong','right'};
timeZero=GetSecs; % We >force< you to have PTB in the path for this so we know that GetSecs is present
 k=0; response=0;
 
dummyStim=stim;
system('say booting arduino');

if dpy.NumSpec==4
    dummyStim.stimLMS.dir=[1 1 1 1];
elseif dpy.NumSpec==3
    dummyStim.stimLMS.dir=[1 1 1];
elseif dpy.NumSpec==2
    dummyStim.stimLMS.dir=[1 1];
end
dummyStim.stimLMS.scale=.1;
[dummyResponse,dpy]=tetra_led_doLEDTrial_5LEDs(dpy,dummyStim,q,s,1); % This should return 0 for an incorrect answer and 1 for correct

%prompt to press 1 to start
toStart=-1;
pause(1);
system('say Press 1 to start')
while(toStart<0)    
    startString=GetChar; %awaiting 1
    toStart=str2double(startString);
  
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
    
    [response,dpy]=tetra_led_doLEDTrial_5LEDs(dpy,stim,q,s); % This should return 0 for an incorrect answer and 1 for correct
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
% 
% if (k == trialsDesired)
%             system('say all trials complete');
% end

figure()
plot(q.intensity(1:q.trialCount));
Data.qInfo=q;
Data.qIntensity(1:q.trialCount,1)=q.intensity(1:q.trialCount)'; %save out the intensity estimates (log(contrast) per trial)
try
    title(sprintf('LMpeak %d at %.1f Hz Trial %d',dpy.LMpeak,dpy.Freq,dpy.Repeat))
catch
    title(sprintf('%s cone at %.1f Hz Trial %d',dpy.ExptID,dpy.Freq,dpy.Repeat))
end
t=QuestMean(q);		% Recommended by Pelli (1989) and King-Smith et al. (1994). Still our favorite.
sd=QuestSd(q);
contrastThresh=10^(t)*100;
contrastStDevPos=(10^(t)*100)-(10^(t-sd)*100);
contrastStDevNeg=(10^(t+sd)*100)-(10^(t)*100);
try   
    fprintf('Experiment Condition: %s Freq: %.1f testLMpeak: %d\n',dpy.ExptID,dpy.Freq,dpy.LMpeak);
catch
    fprintf('Experiment Condition: %s Freq: %.1f \n',dpy.ExptID,dpy.Freq);
end
fprintf('Final threshold estimate (mean+-sd) is %.2f +- %.2f\n',t,sd);
fprintf('Final threshold in actual contrast units is %.2f%% SD is + %.2f%% -%.2f%%\n',contrastThresh,contrastStDevPos,contrastStDevNeg);
% TODO HERE - ADD IN AUTO SAVE FOR DATA...

Data.Date=datestr(now,30); %current date with time

Data.rawThresh=t;
Data.rawStDev=sd;
Data.contrastThresh=contrastThresh;
Data.contrastStDevPos=contrastStDevPos;
Data.contrastStDevNeg=contrastStDevNeg;
Data.dpy=dpy;


