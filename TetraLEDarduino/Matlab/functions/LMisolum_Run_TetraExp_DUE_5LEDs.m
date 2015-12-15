function Data=LMisolum_Run_TetraExp_DUE_5LEDs(dpy,s)
% Data = MCS_Run_TetraExp_DUE_5LEDs(dpy,s)
%
% Runs the experiment using details from dpy. s is the serial connection.
%
% dpy should contain:
% dpy.SubID     = the SubjectID
% dpy.NumSpec   = the number of cone spectra to use, either 2 3 or 4
% dpy.ExptID    = the experiment ID
% dpy.Repeat    = which session number is it
% dpy.Freq      = the frequency (Hz) of the stimulus
% dpy.NumStimLevels      = the number of contrast levels to test at in MCS
% dpy.NumTrialsPerLevel  = the number of trials to run at each contrast level
%
% Outputs 'Data', containing final thresholds, etc.
%
% % ARW 021515
% edited by LEW 200815 as a function to output 'Data'
% edited by LEW 131115 to use method of constant stimuli

pause(2);
fprintf('\n****** Experiment Running ******\n \n');
BITDEPTH=12;
LEDamps=uint16([0,0,0,0,0]);
nLEDsTotal=length(LEDamps);
% This code presents two flicker intervals - randomising which interval
% contains the target

% Initialize the display system
% Load LEDspectra calib contains 1 column with wavelengths, then the LED calibs
load('LEDspectra_151215.mat'); %load in calib for the prizmatix
LEDcalib=LEDspectra; %if update the file loaded, the name only has to be updated here for use in rest of code
LEDcalib(LEDcalib<0)=0; %set any negative values to 0
clear LEDspectra %we'll use this variable name later so clear it here

dpy.WLrange=(400:1:720)'; %must use range from 400 to 720

% use white spectra to get baselevels for each LED (so white light as
% background), and resample the LEDcalib spectra to the desired WL range
[dummy, LEDspectra] = LED2white(LEDcalib,dpy); % outputs scaled baselevels and resampled LEDspectra based on WL
%baselevelsLEDS=baselevels/2; %we want the baselevels at half their scaled levels
baselevelsLEDS=[1,1,1,1,1];
LEDbaseLevel=uint16((baselevelsLEDS)*(2^BITDEPTH)); % convert for sending to arduino

%specify the LEDs in use in this experiment (usually all 5) and keep the
%necessary spectra for each
LEDsToUse=find(LEDbaseLevel);
dpy.LEDspectra=LEDspectra(:,LEDsToUse); %specify which LED spectra to keep
dpy.LEDsToUse=LEDsToUse; % save to dpy
dpy.nLEDsTotal=nLEDsTotal; % save number of LEDs
dpy.nLEDsToUse=length(dpy.LEDsToUse); %duplicate info from above... check which is used in later code

% Save baselevels and bitDepth to dpy
dpy.baselevelsLEDS=baselevelsLEDS;
dpy.bitDepth=BITDEPTH;
dpy.backLED.dir=baselevelsLEDS;

dpy.backLED.scale=.3; % LEDs on at 50%

%CHECK THIS *******************************
dpy.LEDbaseLevel=round(dpy.backLED.dir*dpy.backLED.scale*(2.^dpy.bitDepth-1)); % Set just the LEDs we're using to be on a 50%
%*******************

% Set the modulation rate
dpy.modulationRateHz=dpy.Freq;

% Check whether or not an Lprime position has been set, if not set it to a
% default in case it is need to run the experiment (e.g. in Lprime
% isolating condition)
try
    dpy.LprimePosition = dpy.LprimePosition;
    % Using the specified Lprime LambdaMax
catch
    dpy.LprimePosition=0.5; %default position of the Lprime peak in relation to L and M cone peaks: 0.5 is half way between, 0 is M cone and 1 is L cone
    % Using default Lprime LambdaMax
end

% Set up the parameters for the possible stimuli - the thresholds
% for different opponent channels will be different - we estimate that they
% are .01 .02 and .05 for (L-M), L+M+S and s-(L+M)respectively (r/g, lum, s-cone)

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
    case {'LM'}
        if dpy.NumSpec==4
            %stim.stimLMS.dir=[0.5 0 -1 0]; %
            stim.stimLMS.scale=.01; %5% is 0.05
            stim.stimLMS.maxTestLevel = 2.15; %theta max
            stim.stimLMS.minTestLevel = 1.75;%theta min
        elseif dpy.NumSpec==3
            dpy.ConeTypes='LMS';
            %stim.stimLMS.dir=[0.3233 -.9463 0]; %
            stim.stimLMS.scale=.03; %5% is 0.05
            stim.stimLMS.maxTestLevel = 2.15;
            stim.stimLMS.minTestLevel = 1.75;
        end;
        thisExp='LM';
        
    case {'LLP'}
        if dpy.NumSpec==4
            %stim.stimLMS.dir=[0.5 -1 0 0]; %
            stim.stimLMS.scale=.02; %5% is 0.05
            stim.stimLMS.maxTestLevel = 2.15;
            stim.stimLMS.minTestLevel = 1.75;
        elseif dpy.NumSpec==3
            dpy.ConeTypes='LLpS';
            %stim.stimLMS.dir=[0.5 -1 0]; %
            stim.stimLMS.scale=.03; %5% is 0.05
            stim.stimLMS.maxTestLevel = 2.15;
            stim.stimLMS.minTestLevel = 1.75;
        end
        thisExp='LLp';
        
    case {'LPM'}
        if dpy.NumSpec==4
            %stim.stimLMS.dir=[0 0.5 -1 0]; %
            stim.stimLMS.scale=.02; %5% is 0.05
            stim.stimLMS.maxTestLevel = 2.15;
            stim.stimLMS.minTestLevel = 1.75;
        elseif dpy.NumSpec==3
            dpy.ConeTypes='LpMS';
            %stim.stimLMS.dir=[0.5 -1 0]; %
            stim.stimLMS.scale=.03; %5% is 0.05
            stim.stimLMS.maxTestLevel = 2.15;
            stim.stimLMS.minTestLevel = 1.75;
        end
        thisExp='LpM';
    otherwise
        error ('Incorrect experiment type');
end

% Create the series of trials to present in the method of constant stimuli
intervalSize=(stim.stimLMS.maxTestLevel-stim.stimLMS.minTestLevel)/(dpy.NumStimLevels-1); %determine the interval size using min, max and num stim levels
dpy.stimLevels=(stim.stimLMS.minTestLevel:intervalSize:stim.stimLMS.maxTestLevel)'; %create the stimulus levels
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
    %set the tTest value (i.e. the contrast level for the current trial)
    tTest=dpy.allStimTrialLevels(thisTrial);
    dpy.theta=tTest;
    Lval=abs(cos(tTest));
    Mval=abs(sin(tTest));
    if dpy.NumSpec==4
        switch thisExp
            case {'LM'} 
                stim.stimLMS.dir=[Lval, 0, -Mval, 0];
            case {'LLp'}
                stim.stimLMS.dir=[Lval, -Mval, 0, 0];
            case {'LpM'}
                stim.stimLMS.dir=[0, Lval, -Mval, 0];
        end

    elseif dpy.NumSpec==3
        stim.stimLMS.dir=[Lval, -Mval, 0];
    end
    
    timeSplit=GetSecs;
    
    if exit==0
        [response,dpy]=LMisolum_tetra_led_doLEDTrial_5LEDs(dpy,stim,s); % This should return 0 for an incorrect answer and 1 for correct
        
        % Check if the response was given, and whether 'q' was pressed to quit
        % experiment
        if (response ~=-1)
            fprintf('Trial %3d at %5.2f is %s\n',thisTrial,tTest,char(wrongRight(response+1)));
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
    plotResponseData(thisLevel,1)=dpy.stimLevels(thisLevel); %name of each level
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
    percentCorrect=(plotResponseData(:,2)/plotResponseData(:,3))*100;
    Data.PercentCorrect=cat(2,plotResponseData(:,1),percentCorrect);
end
figure()
scatter(plotResponseData(:,1),plotResponseData(:,2))
try
    title(sprintf('LMpeak %d at %.1f Hz Trial %d',dpy.LMpeak,dpy.Freq,dpy.Repeat))
catch
    title(sprintf('%s cond at %.1f Hz Trial %d',dpy.ExptID,dpy.Freq,dpy.Repeat))
end

% %fit psychometric function to data
% searchGrid.alpha = 0:1:30;
% searchGrid.beta = 0:0.5:10;
% searchGrid.gamma = .5;
% searchGrid.lambda = 0.02;
% 
% paramsFree = [1 1 0 0];
% PF = @PAL_CumulativeNormal;
% 
% [Data.Fit.paramValues,Data.Fit.LL,Data.Fit.exitFlag,Data.Fit.output] = PAL_PFML_Fit(plotResponseData(:,1),plotResponseData(:,2),...
%     plotResponseData(:,3),searchGrid,paramsFree,PF);
% Data.contrastThresh=Data.Fit.paramValues(1)*100;
% 
% try
%     fprintf('Experiment Condition: %s    Freq: %.1f testLMpeak: %d\n',dpy.ExptID,dpy.Freq,dpy.LMpeak);
% catch
%     fprintf('Experiment Condition: %s    Freq: %.1f \n',dpy.ExptID,dpy.Freq);
% end
% if Data.Fit.exitFlag == 1
%     Data.fitExit='successful';
% elseif Data.Fit.exitFlag == 0
%     Data.fitExit='not successful';
% end
% fprintf('Final threshold estimate is %.2f%%     Fit %s',Data.contrastThresh,Data.fitExit); %first val is threshold
Speak('Condition complete','Daniel')
Data.Date=datestr(now,30); %current date with time

Data.dpy=dpy;


