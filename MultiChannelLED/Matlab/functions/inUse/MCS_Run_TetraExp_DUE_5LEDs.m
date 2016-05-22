function Data=MCS_Run_TetraExp_DUE_5LEDs(dpy,s)
% Data = MCS_Run_TetraExp_DUE_5LEDs(dpy,s)
%
% Runs the experiment using details from dpy. 
% s is the serial connection.
%
% Sets up and runs trials for a method of constant stimuli (MCS) - creates
% the contrast levels to test at using the specified number of levels from
% dpy.NumStimLevels and max contrast values set for each experiment ID type
% in this script - max values based on what is possible to produce for each
% ID (and number of cone spectra used)
%
% This code presents two flicker intervals - randomising which interval
% contains the target
%
% dpy should contain:
% dpy.SubID     = the SubjectID
% dpy.NumSpec   = the number of cone spectra to use, either 2 3 or 4
% dpy.ExptID    = the experiment ID, should be single ID: LM, LMS, L, M, S
% dpy.Repeat    = which session number is it
% dpy.Freq      = the frequency (Hz) of the stimulus
% dpy.NumStimLevels      = the number of contrast levels to test at
% dpy.NumTrialsPerLevel  = the number of trials to run at each contrast level
%
% Outputs 'Data', containing final thresholds, etc.
%
% % ARW 021515
% edited by LEW 200815 as a function to output 'Data'
% edited by LEW 131115 to use method of constant stimuli


pause(2);
fprintf('\n****** Experiment Running ******\n \n');

% Initialize the display system
% Load LEDspectra calib: contains 1 column with wavelengths, then the LED calibs
theSpectra=load('LEDspectra_220416.mat'); %load in latest calib for the prizmatix
%save the spectra in LEDcalib
spectraVar=fieldnames(theSpectra); %get name of the field containing spectra
LEDcalib=theSpectra.(spectraVar{1}); %save in LEDcalib variable
LEDcalib(LEDcalib<0)=0; %set any negative values to 0

%normalise the spectra scale so 0 to 1
maxVal=max(max(LEDcalib(:,2:end))); %get max val across all spectra, exclude the wavelength column
normLEDcalib(:,1)=LEDcalib(:,1); %save wavelengths into first column of normLEDcalib
for thisLED = 1:size(LEDcalib,2)-1 %for each LED
    normLEDcalib(:,1+thisLED)=LEDcalib(:,1+thisLED)./maxVal; %divide each value (from each row) by the maxVal
end

LEDcalib=normLEDcalib; %redefine LEDcalib as the normalised calibration spectra


dpy.WLrange=(400:1:720)'; %set the wavelength ramge. must use range from 400 to 720
BITDEPTH=12; %set the bitdepth

%************ IF CHANGING NUMBER OF LEDS USED, UPDATE THESE VARIABLES *****
baselevelsLEDS=[1,1,1,1,1]; %equally weight all LEDs for the baselevel values
LEDamps=uint16([0,0,0,0,0]); %pre-set LED amp values to zero
LEDsToUse=[1,2,3,4,5]; % the LEDs you want to use, where 1 is the 410nm LED, and 5 is 630nm LED
%**************************************************************************
dpy.LEDsToUse = LEDsToUse; %set the LEDsToUse in dpy
nLEDsTotal=length(LEDamps); %number of LEDs

%the dpy.NumSpec determines how many cone spectra are used,i.e. LMS LLpMS
%or maybe even just 2 cones (built this in incase back testing theory for 
%how a tetrachromat would respond on 3 cone spectra stimuli)
if dpy.NumSpec==4 %if tetra stim
    %if using 4 cones, need to determine the peak of the Lprime
    LprimePos=dpy.LprimePosition; %position of peak between the L and M cones, 0.5 is half way
    %create the coneSpectra. use the LprimePos to interpolate the Lprime
    %spectra from L and M cone fundamentals
    coneSpectra=creatingLprime(dpy); %outputs the L L' M S spectra, with first column containing wavelengths
    fprintf('LprimePos is %.2f\n',LprimePos);
elseif dpy.NumSpec==3; %if LMS stim
    if isfield(dpy,'shiftCone')==1 
        %if a shifted cone has been specified, create the spectra for it
        coneSpectra=creatingShiftedConeSpectra(dpy);
    else %else default to using stockman LMS spectra
        dpy.ConeTypes='LMS';
        coneSpectra=creatingLMSspectra(dpy);
    end
elseif dpy.NumSpec==2;
    %must specifiy a peak for the only cone in the middle/long region
    dpy.LMpeak = 565; %can build this into script to be prompted if it'll be used. For now it's a place holder.
    [coneSpectra,dpy]=creating2coneSpectra(dpy); %where 'LMpeak' is lambdaMax of the cone in longwavelength region
end
dpy.coneSpectra = coneSpectra; %save in dpy structure
dpy.coneSpectra(isnan(dpy.coneSpectra))=0; %set nans to zero


%% resample the LED spectra using wavelength range
for thisLED = 1:size(LEDcalib,2)-1 % column1 is wavelengths
    LEDspectra(:,thisLED) = interp1(LEDcalib(:,1),LEDcalib(:,1+thisLED),dpy.WLrange);
end
LEDspectra(LEDspectra<0) = 0; %set any negative values to 0

% for now, use values set earlier (1's)
baselevelsLEDS = baselevelsLEDS(:,LEDsToUse);
% keep the necessary spectra for each LED in use (as specified above)
dpy.LEDspectra=LEDspectra(:,LEDsToUse); %specify which LED spectra to keep
dpy.LEDsToUse=LEDsToUse; % save to dpy
dpy.nLEDsTotal=nLEDsTotal; % save number of LEDs
dpy.nLEDsToUse=length(dpy.LEDsToUse); %duplicate info from above... check which is used in later code

% Save baselevels and bitDepth to dpy
dpy.baselevelsLEDS=baselevelsLEDS;
dpy.bitDepth=BITDEPTH;
dpy.backLED.dir=baselevelsLEDS;

dpy.backLED.scale=.5; % LEDs on at 50%

%Don't think this number is actually used again in the code...
dpy.LEDbaseLevel=round(dpy.backLED.dir*dpy.backLED.scale*(2.^dpy.bitDepth)); % Set just the LEDs we're using to be on a 50%

% Set the modulation rate using specified frequency
dpy.modulationRateHz=dpy.Freq;

% Check whether or not an Lprime position has been set, if not set it to a
% default in case it is needed to run the experiment (e.g. in Lprime
% isolating condition)
try
    dpy.LprimePosition = dpy.LprimePosition;
    % Using the specified Lprime LambdaMax
catch
    dpy.LprimePosition=0.5; %default position of the Lprime peak in relation to L and M cone peaks: 0.5 is half way between, 0 is M cone and 1 is L cone
    % Using default Lprime LambdaMax
end

%% set parameters for stimuli
% Set up the parameters for the possible stimuli - the thresholds
% for different opponent channels will be different - plus they will be
% different depending on whether 3 or 4 cones are used in the coneSpectra

% For each possible condition we need to record the max contrast value that
% we are able to produce, and set the min and max values we would want to
% use in a method of constant stimuli (based on educated guesses
% surrounding likely thresholds).  We  later use the information from
% dpy to build the list of contrast levels and the number of trials for
% each, so we can randomise the presentation of the stimuli.

% For the current condition, check the ExptID and set stimulus values
% specific for that condition and for the number of cone spectra being
% assumed (i.e. contrast has to be much lower when accounting for 4 cones)
switch dpy.ExptID
    case {'L'} %L cone isolating
        if dpy.NumSpec==4 %4 cones used L Lp M S
            stim.stimLMS.dir=[1 0 0 0]; % L cone isolating
            stim.stimLMS.maxCont = .008; %max possible?
            stim.stimLMS.maxTestLevel = .005; %max level to use
            stim.stimLMS.minTestLevel = .0000001; %min level to use
        elseif dpy.NumSpec==3 %3 cones used L M S
            if isfield(dpy,'ConeTypes')==1 %see if ConeTypes is already set - not sure why, think it has to be set before here?!
            else %default to setting as LMS coneTypes if not
                dpy.ConeTypes='LMS';
            end
            stim.stimLMS.dir=[1 0 0]; % L cone isolating
            stim.stimLMS.maxCont= .055;
            stim.stimLMS.maxTestLevel = .05;
            stim.stimLMS.minTestLevel = .0000001;
        end
        thisExp='L';
        
    case {'LP'}
        if dpy.NumSpec==4 %4 cones
            stim.stimLMS.dir=[0 1 0 0]; % L' cone isolating
            if dpy.LprimePosition<0.25 || 0.75<dpy.LprimePosition
                stim.stimLMS.maxCont= .0007;
                stim.stimLMS.maxTestLevel = .005;
                stim.stimLMS.minTestLevel = .0000001;
            else
                stim.stimLMS.maxCont= .005;
                stim.stimLMS.maxTestLevel = .0045;
                stim.stimLMS.minTestLevel = .0000001;
            end
        elseif dpy.NumSpec==3
            if isfield(dpy,'ConeTypes')==1
            else %default to setting as LpMS coneTypes
                dpy.ConeTypes='LpMS';
            end
            stim.stimLMS.dir=[1 0 0]; % L cone isolating
            stim.stimLMS.maxCont= .035;
            stim.stimLMS.maxTestLevel = .05;
            stim.stimLMS.minTestLevel = .0000001;
        else
            error('Check NumSpec for this condition')
        end
        thisExp='Lp';
        
    case {'M'}
        if dpy.NumSpec==4 %4 cones
            stim.stimLMS.dir=[0 0 1 0]; % M cone isolating
            stim.stimLMS.maxCont= .008;
            stim.stimLMS.maxTestLevel = .005;
            stim.stimLMS.minTestLevel = .0000001;
        elseif dpy.NumSpec==3 %3 cones
            if isfield(dpy,'ConeTypes')==1
            else %default to setting as LMS coneTypes
                dpy.ConeTypes='LMS';
            end
            stim.stimLMS.dir=[0 1 0]; % M cone isolating
            stim.stimLMS.maxCont= .035;
            stim.stimLMS.maxTestLevel = .05;
            stim.stimLMS.minTestLevel = .0000001;
        end
        thisExp='M';
        
    case {'LM'}
        if dpy.NumSpec==4
            stim.stimLMS.dir=[0.5 0 -1 0]; %
            stim.stimLMS.maxCont= .005;
            stim.stimLMS.maxTestLevel = .01;
            stim.stimLMS.minTestLevel = .0000001;
        elseif dpy.NumSpec==3
            dpy.ConeTypes='LMS';
            stim.stimLMS.dir=[0.5 -1 0]; %
            stim.stimLMS.maxCont= .045;
            stim.stimLMS.maxTestLevel = .03;
            stim.stimLMS.minTestLevel = .0000001;
        end;
        thisExp='LM';
        
    case {'LLP'}
        if dpy.NumSpec==4
            stim.stimLMS.dir=[0.5 -1 0 0]; %
            stim.stimLMS.maxCont= .005;
            stim.stimLMS.maxTestLevel = .007;
            stim.stimLMS.minTestLevel = .0000001;
        elseif dpy.NumSpec==3
            dpy.ConeTypes='LLpS';
            stim.stimLMS.dir=[0.5 -1 0]; %
            stim.stimLMS.maxCont= .045;
            stim.stimLMS.maxTestLevel = .05;
            stim.stimLMS.minTestLevel = .0000001;
        end
        thisExp='LLp';
        
    case {'LPM'}
        if dpy.NumSpec==4
            stim.stimLMS.dir=[0 0.5 -1 0]; %
            stim.stimLMS.maxCont= .005;
            stim.stimLMS.maxTestLevel = .007;
            stim.stimLMS.minTestLevel = .0000001;
        elseif dpy.NumSpec==3
            dpy.ConeTypes='LpMS';
            stim.stimLMS.dir=[0.5 -1 0]; %
            stim.stimLMS.maxCont= .045;
            stim.stimLMS.maxTestLevel = .05;
            stim.stimLMS.minTestLevel = .0000001;
        end
        thisExp='LpM';
        
    case {'LMS'}
        if dpy.NumSpec==4
            stim.stimLMS.dir=[1 0 1 1]; %
            stim.stimLMS.maxCont= .02;
            stim.stimLMS.maxTestLevel = .02;
            stim.stimLMS.minTestLevel = .0000001;
        elseif dpy.NumSpec==3
            dpy.ConeTypes='LMS';
            stim.stimLMS.dir=[1 1 1]; %
            stim.stimLMS.maxCont= .1;
            stim.stimLMS.maxTestLevel = .07;
            stim.stimLMS.minTestLevel = .0000001;
        end
        thisExp='LMS';
        
    case {'LLpMS'}
        if dpy.NumSpec==4
            stim.stimLMS.dir=[1 1 1 1]; %
            stim.stimLMS.maxCont= .02;
            stim.stimLMS.maxTestLevel = .02;
            stim.stimLMS.minTestLevel = .0000001;
        else
            error('Num spec must be set to 4 to run LLpMS')
        end
        thisExp='LLpMS';
        
        
    case {'S'}
        if dpy.NumSpec==4
            stim.stimLMS.dir=[0 0 0 1]; % S cone isolating
            stim.stimLMS.maxCont= .25;
            stim.stimLMS.maxTestLevel = .20;
            stim.stimLMS.minTestLevel = .0000001;
        elseif dpy.NumSpec==3
            dpy.ConeTypes='LMS';
            stim.stimLMS.dir=[0 0 1]; % S cone isolating
            stim.stimLMS.maxCont= .25;
            stim.stimLMS.maxTestLevel = .20;
            stim.stimLMS.minTestLevel = .0000001;
        elseif dpy.NumSpec==2
            stim.stimLMS.dir=[0 1]; % S cone isolating
            stim.stimLMS.maxCont= .25;
            stim.stimLMS.maxTestLevel = .10;
            stim.stimLMS.minTestLevel = .0000001;
        end
        thisExp='S';
        
    case {'TESTLM'}
        if dpy.NumSpec==4
            stim.stimLMS.dir=[0 1 0 0]; % testLM cone isolating
            stim.stimLMS.maxCont= .008;
            stim.stimLMS.maxTestLevel = .008;
            stim.stimLMS.minTestLevel = .0000001;
        elseif dpy.NumSpec==2
            stim.stimLMS.dir=[1 0]; % testLM cone isolating
            stim.stimLMS.maxCont= .2;
            stim.stimLMS.maxTestLevel = .1;
            stim.stimLMS.minTestLevel = .0000001;
        else
            error('Incorrect NumSpec for this condition')
        end
        thisExp='testLM';
        
    otherwise
        error ('Incorrect experiment type');
end

% Create the series of trials to present in the method of constant stimuli
% We are going to do this on a log scale so we don't have too many levels
% at the high 'easy-to-see' end

%in case just in testing mode using pre-defined contrasts check for the
%indicator
try
    if dpy.testingMode == 1
        dpy.stimLevels = dpy.TestingStimLevel;
        dpy.allStimTrialLevels = repmat(dpy.stimLevels,dpy.NumTrialsPerLevel,1);
    end
catch %if doesn't exist, proceed as normal
end   
    %for now, don't log scale the stim values. kept code for dpy.stimLevels
    %when log scaled so easy to re-introduce
%dpy.stimLevels=logspace(log10(stim.stimLMS.minTestLevel),log10(stim.stimLMS.maxTestLevel),dpy.NumStimLevels)'; %create the stimulus levels
dpy.stimLevels=[stim.stimLMS.minTestLevel:((stim.stimLMS.maxTestLevel-stim.stimLMS.minTestLevel)/(dpy.NumStimLevels-1)):stim.stimLMS.maxTestLevel]';
dpy.allStimTrialLevels=Shuffle(repmat(dpy.stimLevels,dpy.NumTrialsPerLevel,1)); %produce list of all the contrast levels (i.e. all trials) and shuffle them

% Run the trials.
% On each trial we run one of the pre-defined stimulus contrast levels that have
% been pre-shuffled in dpy.allStimTrialLevels
wrongRight={'wrong','right'};
timeZero=GetSecs; % We >force< you to have PTB in the path for this so we know that GetSecs is present

%prompt to press 1 to start
toStart=-1;
pause(1);
Speak('Press 1 to start','Daniel');
while(toStart<0)
    startString=GetChar; %awaiting 1 to start
    toStart=str2double(startString);
end
Speak('Experiment beginning','Daniel');
pause(1)

k=0; 
exit=0;

% Run the trials
for thisTrial = 1:length(dpy.allStimTrialLevels)
    dpy.theTrial=thisTrial; %save the current trial in dpy so that the target interval and wrong/right info can be saved within next function
    %set the TestTrial value (i.e. the contrast level for the current trial)
    TestTrial=dpy.allStimTrialLevels(thisTrial);
    
    timeSplit=GetSecs;
    stim.stimLMS.scale=TestTrial; %assign TestTrial to stim
    
    if exit==0
        [response,dpy]=MCS_tetra_led_doLEDTrial_5LEDs(dpy,stim,s); % This should return 0 for an incorrect answer and 1 for correct
        
        % Check if the response was given, and whether 'q' was pressed to quit
        % experiment
        if (response ~=-1)
            fprintf('Trial %3d at %.4f is %s\n',thisTrial,TestTrial,char(wrongRight(response+1)));
            timeZero=timeZero+GetSecs-timeSplit;
            k=k+1;
        else
            disp('Quitting...');
            Speak('Quitting before all trials complete','Daniel');
            exit=1;
        end
        
    elseif exit==1
        continue
    end
end

% plot the percent correct curves
% concatenate columns with contrast level and hit/miss code
try
    responseData=cat(2,dpy.allStimTrialLevels,dpy.Response);
catch %if experiment was exited before end the values have to be altered for the number of trials actually completed
    dpy.allStimTrialLevels=dpy.allStimTrialLevels(1:k,1);
    dpy.Response=dpy.Response(1:k,1);
    responseData=cat(2,dpy.allStimTrialLevels,dpy.Response);
end

for thisLevel = 1:length(dpy.stimLevels)
    plotResponseData(thisLevel,1)=dpy.stimLevels(thisLevel)*100; %name of each level *100 so in contrast %
    totalTrials=0;
    totalHits=0;
    for thisTrial=1:length(dpy.allStimTrialLevels)
        if responseData(thisTrial,1)==dpy.stimLevels(thisLevel); %if row matches current level, save the response info
            totalTrials=totalTrials+1;
            if responseData(thisTrial,2)==1; %if a hit
                totalHits=totalHits+1;
            end
        end
    end
    plotResponseData(thisLevel,2)=totalHits;
    plotResponseData(thisLevel,3)=totalTrials;
    Data.CombinedResponseData=plotResponseData;
    percentCorrect=(plotResponseData(:,2)./plotResponseData(:,3))*100;
    Data.PercentCorrect=cat(2,plotResponseData(:,1),percentCorrect);
end

scatter(Data.PercentCorrect(:,1),Data.PercentCorrect(:,2));
set(gca,'YLim',[0,100]);
try
    title(sprintf('LMpeak %d at %.1f Hz Trial %d',dpy.LMpeak,dpy.Freq,dpy.Repeat))
catch
    title(sprintf('%s cond at %.1f Hz Trial %d',dpy.ExptID,dpy.Freq,dpy.Repeat))
end

%fit psychometric function to data
searchGrid.alpha = 0:1:30;
searchGrid.beta = 0:0.5:10;
searchGrid.gamma = .5;
searchGrid.lambda = 0.02;

paramsFree = [1 1 0 0];
PF = @PAL_CumulativeNormal;

[Data.Fit.paramValues,Data.Fit.LL,Data.Fit.exitFlag,Data.Fit.output] = PAL_PFML_Fit(plotResponseData(:,1),plotResponseData(:,2),...
    plotResponseData(:,3),searchGrid,paramsFree,PF);
Data.contrastThresh=Data.Fit.paramValues(1);

try
    fprintf('Experiment Condition: %s    Freq: %.1f testLMpeak: %d\n',dpy.ExptID,dpy.Freq,dpy.LMpeak);
catch
    fprintf('Experiment Condition: %s    Freq: %.1f \n',dpy.ExptID,dpy.Freq);
end
if Data.Fit.exitFlag == 1
    Data.fitExit='successful';
elseif Data.Fit.exitFlag == 0
    Data.fitExit='not successful';
end
fprintf('Final threshold estimate is %.2f%%     Fit %s\n\n',Data.contrastThresh,Data.fitExit); %first val is threshold
Speak('Condition complete','Daniel');
Data.Date=datestr(now,30); %current date with time

Data.dpy=dpy;


