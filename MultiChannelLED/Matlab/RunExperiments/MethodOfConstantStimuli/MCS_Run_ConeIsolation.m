% Script to specify experiment conditions and then run the experiment.
% (make sure arduino script is already running).
% 
% Runs specified conditions at different
% frequencies to acquire thresholds.
%
% Specify dpy structure to send to the MCS_Run_TetraExp_DUE_5LEDs script.
% dpy should contain:
% dpy.SubID              = the SubjectID 
% dpy.NumSpec            = the number of cone spectra to use, either 2 3 or 4
% dpy.ExptID             = the experiment ID
% dpy.Repeat             = which session number is it
% dpy.Freq               = the frequency (Hz) of the stimulus  
% dpy.NumStimLevels      = the number of contrast levels to test at in MCS
% dpy.NumTrialsPerLevel  = the number of trials to run at each contrast level
%
% written by LEW 20/08/15
% editted by LEW on 13/11/15 for use with Method of Constant Stimuli

clear all; close all;
%Add the necessary folder to the path
addpath(genpath('/Users/wade/Documents/GitHub_Multispectral/TetraLEDardui4no'))

%connect to arduino
s=ConnectToArduino;
%Run a dummy trial to prepare the stimulus
dummyTrial(s);

%set some of the experiment parameters
dpy.NumSpec=4; %this is the number of assumed cones used to create stim (e.g. LMS, or L Lp M S, etc)
dpy.LprimePosition=0.5; %set this if running and experiments with Lprime, 0.5 puts the peak of Lp between L and M
theExptID={'L'}; %set the experiment IDs you want to test, e.g.: LM, LLP, LPM
theFreq=[4]; %the frequencies to test for each experiment ID

%Set details for the method of constant stimuli here, i.e. num levels, num
%trials at each level.  Details of max and min levels will be set within the 
%Run function.  Need to make sure the values don't exceed the max available.
%These values will vary depending on the experiment ID
dpy.NumStimLevels = 5; %the number of levels for the method of constant stim
dpy.NumTrialsPerLevel = 10; %the number of trials for each level

% Ask the user to enter a Subject ID number
SubID=-1; 
while(SubID<1)
    SubID=input ('Enter Subject ID, e.g. 001: ','s'); %prompts to enter a subject ID
    if(isempty(SubID))
        SubID=-1;
    end
end
dpy.SubID=SubID;

% Ask the user to enter a session number
Repeat=-1; 
while(Repeat<1)
    RepeatString=input ('Enter the session number for this condition: ','s'); 
    Repeat=str2double(RepeatString);
    if(isempty(Repeat))
        Repeat=-1;
    end
end
dpy.Repeat=Repeat;
tic; %start timer so can output total run time at the end of the experiment

%Create a list of conditions that is properly randomised - a matrix of
%condition codes and freqs, where each row is the given condition and each
%column gives information about that condition (i.e. the code and freq).
%
%First, create array of frequency codes for each expt ID, e.g. if there are three
%IDs and 2 frequencies, it should be a column containing three '1's and three '2's
numExptIDs = length(theExptID);
numFreqs = length(theFreq);
a=1;
for thisfreq = 1:numFreqs;
    freqCodes(a:a+(numExptIDs-1),1) = repmat(thisfreq,numExptIDs,1);
    a=a+numExptIDs;
end

%concatenate the frequency codes with expt ID codes (duplicated for the
%number of frequencies, e.g. a matrix of [1,1;2,1;3,1;1,2;2,2;3,2]
totalCondCodes = cat(2,repmat((1:numExptIDs)',numFreqs,1),freqCodes);

%now shuffle just the order of the rows to randomise the condition order
%but keeping the correct trial combinations i.e. so each expt ID is run at
%each frequency
TotalNumConds=size(totalCondCodes,1);
if TotalNumConds==1 %if there's only one condition
    shuffledConds=totalCondCodes;
else
    shuffledConds = totalCondCodes(randperm(TotalNumConds),:);
end

% Now run each of the conditions in their shuffled order
for thisCond = 1:TotalNumConds
    %specify what the condition expt ID and freq are using codes
    dpy.ExptID=theExptID{(shuffledConds(thisCond,1))}; %first col is ExptIDs
    dpy.Freq=theFreq((shuffledConds(thisCond,2))); %second col is freq IDs
    fullCondName=sprintf('%s_Freq%d',dpy.ExptID,dpy.Freq);
    
    % Now send experiment details out and start experiment trials.
    Data=MCS_Run_TetraExp_DUE_5LEDs(dpy,s);
    
    %save out a file containing the contrastThresh, SubID, experimentType, freq and
    %Session num
    
    %go to wherever you want to save it
    cd('/Users/wade/Documents/Github_MultiSpectral/TetraLEDarduino/Pilot_Data')
    
    save(sprintf('SubID%s_Expt%s_Freq%d_Rep%d_%s.mat',...
        dpy.SubID,dpy.ExptID,dpy.Freq,dpy.Repeat,Data.Date),'Data');
    %save the figure
    savefig(sprintf('SubID%s_Expt%s_Freq%d_Rep%d_%s.fig',...
        dpy.SubID,dpy.ExptID,dpy.Freq,dpy.Repeat,Data.Date));
    fprintf('\nSubject %s data saved\n',dpy.SubID);
    fprintf('\n******** End of Condition ********\n');
    CondName=sprintf('%s',dpy.ExptID);
    FreqName=sprintf('Freq%d',dpy.Freq);
    TempData.Thresh.(CondName).(FreqName)=Data.contrastThresh;    
    TempData.fitExit.(CondName).(FreqName)=Data.fitExit;    

    AllData.OrderOfConditions{thisCond}=fullCondName; %save out order the conditions were presented in
    AllData.(CondName).(FreqName)=Data; %save all the Data associated with the condition
    
    %clear the Data and Figure before creating stimuli for next condition
    clear Data; close all
end
Speak('All conditions complete','Daniel');
finalDate=datestr(now,30);
save(sprintf('SubID%s_MCS_Rep%d_%s.mat',...
    dpy.SubID,dpy.Repeat,finalDate),'AllData');
%turn off LEDs and close connection to ardunio
CloseArduino(s);%close connection to arduino

%output the thresholds calculated for each condition (just based on trials
%in this session)
for thisCond=1:length(theExptID)
    theCondName=theExptID{thisCond};
    for thisFreq=1:length(theFreq)
        theFreqName=sprintf('Freq%d',theFreq(thisFreq));
        fprintf('\nContrast Threshold for Cond %s  %s : %.2f%%      Fit %s\n',...
        theCondName,theFreqName,TempData.Thresh.(theCondName).(theFreqName),TempData.fitExit.(CondName).(FreqName));
    end
end

%output total time for experiment
timeElapsed=toc/60;
fprintf('Experiment complete in %.3f minutes\n',timeElapsed);