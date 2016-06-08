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

clear all; close all; %clear any Data variables that exist and close any figures before running
%Add the necessary folder to the path
addpath(genpath('/Users/wade/Documents/GitHub_Multispectral/MultiChannelLED'))

%connect to arduino
s=ConnectToArduino;
%Run a dummy trial to prepare the stimulus
dummyTrial(s);

%set some of the experiment parameters
dpy.NumSpec=3; %this is the number of assumed cones used to create stim (e.g. LMS, or L Lp M S, etc)
%dpy.LprimePosition=0.5; %set this if running and experiments with Lprime, 0.5 puts the peak of Lp midway between L and M peaks
theExptID={'L'}; %set the experiment ID(s) you want to test, 
theFreq=[10]; %the frequencies to test for each experiment ID, can be one or more (e.g. [2,4,8])
dpy.NumTrials=50; %num trials for staircase

%if you want to fix the L or M cone peak to a different value than the
%stockman ones, set it here: either 'dpy.Lpeak' or 'dpy.Mpeak'. N.B. if you do
%both then the values specified in this experiment will be based on those
%peak, which is useful if you want to test around different means.
dpy.Lpeak=555.5;
dpy.Mpeak=543;

%set how many peak levels should be tested
dpy.NumShiftPeaks = 5; %must be odd number
dpy.shiftSteps = 1.5; %step size of shift in nm
negShifts = -(((dpy.NumShiftPeaks-1)/2)*dpy.shiftSteps):dpy.shiftSteps:0;
posShifts = 0:dpy.shiftSteps:((dpy.NumShiftPeaks-1)/2)*dpy.shiftSteps;
dpy.shiftLevels = [negShifts,posShifts(2:end)]; %create list, excludes one of the zeros so not duplicated


% %Set details for the method of constant stimuli here, i.e. num levels, num
% %trials at each level.  Details of max and min contrast levels will be set within the 
% %Run function (to make sure the values don't exceed the max contrast available
% %for the given experiment ID)
% dpy.NumStimLevels = 6; %the number of levels for the method of constant stim
% dpy.NumTrialsPerLevel = 15; %the number of trials for each level

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
%condition codes and shifts, where each row is the given condition and each
%column gives information about that condition (i.e. the code and shift).
%N.B. this does not interleave the actual trials, just the order in which
%the conditions are presented
%
%First, create a coded array of shifts for each expt ID, so that 
%there is a single column with stacked codes for each condition.  The first 
%shift will be coded as 1, the second as 2, etc., and the number of
%each will be determine by the number of expt IDs
%e.g. if there are three expt IDs and 5 shifts, there should be
%15 rows (3x5), containing three sets of 1:5
numExptIDs = length(theExptID); %number of ExptIDs
numShifts = length(dpy.shiftLevels); %number of shift levels
a=1; %index
for thisshift = 1:numShifts; %for each shift level
    shiftCodes(a:a+(numExptIDs-1),1) = repmat(thisshift,numExptIDs,1); %fill rows with shift code for n Expt IDs
    a=a+numExptIDs; %update index so next shift level code starts below
end

%concatenate the shift codes with expt ID codes (duplicated for the
%number of shifts) to produce a matrix
totalCondCodes = cat(2,repmat((1:numExptIDs)',numShifts,1),shiftCodes);

%now shuffle just the order of the rows to randomise the condition order
%but keeping the correct trial combinations i.e. so each expt ID is run at
%each shift level
TotalNumConds=size(totalCondCodes,1); %number of conditions
if TotalNumConds==1 %if there's only one condition no need to shuffle
    shuffledConds=totalCondCodes; %save as shuffledConds
else
    shuffledConds = totalCondCodes(randperm(TotalNumConds),:); %shuffle and save in shuffledConds
end

% Now run each of the conditions in their shuffled order
for thisCond = 1:TotalNumConds %for each condition
    %specify what the condition expt ID and freq are using codes
    dpy.ExptID=theExptID{(shuffledConds(thisCond,1))}; %first col of shuffledConds is ExptIDs
    dpy.Freq=theFreq; 
    dpy.shiftPeak=dpy.shiftLevels((shuffledConds(thisCond,2))); %second col of shuffledConds is shift IDs
    dpy.shiftCone=dpy.ExptID;
    
    % Now send experiment details out and start experiment trials.
    Data=Quest_Run_TetraExp_DUE_5LEDs(dpy,s);
    
    %store full condition name
    fullCondName=sprintf('%s_peak%.2f',dpy.ExptID,Data.dpy.shiftPeakWL); %save name of condition as string
 
    %save out a file containing the data, SubID, experimentType, freq and
    %Session num - do this for each condition as the experiment runs - if it
    %crashes part way through, not all data will be lost 
    
    %go to wherever you want to save it
    cd('/Users/wade/Documents/Github_MultiSpectral/MultiChannelLED/DataFiles/IndividualConditions')
    
    %save Data
    save(sprintf('SubID%s_Expt%s_Shift%d_Rep%d_%s.mat',...
        dpy.SubID,dpy.ExptID,round(Data.dpy.shiftPeakWL),dpy.Repeat,Data.Date),'Data');
    
    %save the figure - because, why not
    %go to figures folder
    cd('/Users/wade/Documents/Github_MultiSpectral/MultiChannelLED/DataFiles/IndividualConditions/Figures')
    %save figure
    savefig(sprintf('SubID%s_Expt%s_Shift%d_Rep%d_%s.fig',...
        dpy.SubID,dpy.ExptID,round(Data.dpy.shiftPeakWL),dpy.Repeat,Data.Date));
    
    %output text to command window when complete
    fprintf('\nSubject %s data saved\n',dpy.SubID);
    fprintf('\n******** End of Condition ********\n');
    
    %Save Data into a structure for all the conditions
    CondName=sprintf('%s',dpy.ExptID); %Expt ID name
    shiftName=sprintf('Shift%d',round(Data.dpy.shiftPeakWL)); %shift name (rounded up)
    AllData.OrderOfConditions{thisCond}=fullCondName; %save out order the conditions were presented in
    AllData.(CondName).(shiftName)=Data; %save all the Data associated with the condition in appropriate structure
    
    %clear the Data and Figure before creating stimuli for next condition
    clear Data; close all
end
Speak('All conditions complete','Daniel');
finalDate=datestr(now,30);

%go to folder for saving all condition data (in one structure)
cd('/Users/wade/Documents/Github_MultiSpectral/MultiChannelLED/DataFiles/AllConditions')
%save data
allExptIDs=strcat(theExptID{:});
save(sprintf('SubID%s_TestCones%s_numSpec%d_Rep%d_%s.mat',...
    dpy.SubID,allExptIDs,dpy.NumSpec,dpy.Repeat,finalDate),'AllData');

%turn off LEDs and close connection to ardunio
CloseArduino(s);%close connection to arduino

%output the thresholds calculated for each condition (just based on trials
%in this session) in the command window
for thisCond=1:length(theExptID) %for each expt id
    theCondName=theExptID{thisCond}; %get name of expt id
    if strcmp(theCondName,'OrderOfConditions')
        %skip it
        else
    shifts=fieldnames(AllData.(theCondName));
    
    for thisShift=1:length(shifts) %for each shift
        theShiftName=shifts{thisShift}; %get name of shift
        actualWLpeak=AllData.(theCondName).(theShiftName).dpy.shiftPeakWL;
        fprintf('\nContrast Threshold for Cond %s  peak %.2f : %.2f%%  \n',...
            theCondName,actualWLpeak,AllData.(theCondName).(theShiftName).contrastThresh);
        fprintf('\nThe max contrast for Cond %s is %.2f\n',theCondName,(AllData.(theCondName).(theShiftName).dpy.MaxSensorValue.(theCondName)*100));
        AllData.(theCondName).(theShiftName).dpy.MaxSensorValueContrast.(theCondName)=AllData.(theCondName).(theShiftName).dpy.MaxSensorValue.(theCondName)*100;
    
    end
    end
end

%output total time for experiment
timeElapsed=toc/60;
fprintf('Experiment complete in %.3f minutes\n',timeElapsed);