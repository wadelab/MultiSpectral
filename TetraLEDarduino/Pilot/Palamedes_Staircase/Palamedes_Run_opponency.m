% Script to specify experiment conditions and then run the experiment.
% (make sure arduino script is already running).
% 
% Runs specified conditions at different
% frequencies to acquire thresholds.
%
% Specify dpy structure to send to the Run_TetraExp_DUE_5LEDs script.
% dpy should contain:
% dpy.SubID          = the SubjectID 
% dpy.NumSpec        = the number of cone spectra to use, either 2 3 or 4
% dpy.ExptID         = the experiment ID
% dpy.Repeat         = which session number is it
% dpy.Freq           = the frequency (Hz) of the stimulus  
% dpy.NumTrials      = the number of trials to run
%
% written by LEW 20/08/15

clear all; close all;
addpath(genpath('/Users/wade/Documents/GitHub_Multispectral/TetraLEDarduino'))

%connect to arduino
s=ConnectToArduino;
dummyTrial(s)

% set number of trials in staircase
dpy.NumTrials=50;
% Ask the user to enter a Subject ID number
SubID=-1; 
while(SubID<1)
    SubID=input ('Enter Subject ID, e.g. 001: ','s'); %prompts to enter a subject ID
    if(isempty(SubID))
        SubID=-1;
    end
end
dpy.SubID=SubID;

dpy.NumSpec=3;
dpy.LprimePosition=0.5;
theExptID={'LM','LLP','LPM','S'};
theFreq=[2,16]; %the frequencies to test for each condition

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
tic;

%run a dummy trial at start of experiment

%Create a list of conditions that is properly randomised - a matrix of
%condition codes and freqs, where each row is the given condition and each
%column gives information about that condition (i.e. the code and freq).

numExptIDs = length(theExptID);
numFreqs = length(theFreq);

%create array of frequency codes for each expt ID, e.g. if there are three
%IDs and 2 frequencies, it should be a column containing three '1's and three '2's
a=1;
for thisfreq = 1:numFreqs;
    freqCodes(a:a+(numExptIDs-1),1) = repmat(thisfreq,numExptIDs,1);
    a=a+numExptIDs;
end

%concatenate the frequency codes with the expt ID codes (duplicated for the
%number of frequencies, e.g. a matrix of [1,1;2,1;3,1;1,2;2,2;3,2]
totalCondCodes = cat(2,repmat((1:numExptIDs)',numFreqs,1),freqCodes);

%now shuffle just the order of the rows to randomise the condition order
%but keeping the correct trial combinations i.e. so each expt ID is run at
%each frequency
TotalNumConds=length(totalCondCodes);
shuffledConds = totalCondCodes(randperm(TotalNumConds),:);

% for each condition
for thisCond = 1:TotalNumConds
    %specify what the condition expt ID and freq are using codes
    dpy.ExptID=theExptID{(shuffledConds(thisCond,1))}; %first col is ExptIDs
    dpy.Freq=theFreq((shuffledConds(thisCond,2))); %second col is freq IDs
    
    fullCondName=sprintf('%s_Freq%d',dpy.ExptID,dpy.Freq);
    
    % Now send experiment details out and start experiment trials.
    Data=Pal_Run_TetraExp_DUE_5LEDs(dpy,s);
    
    %save out a file containing the contrastThresh, SubID, experimentType, freq and
    %Session num
    
    %go to wherever you want to save it
    cd('/Users/wade/Documents/Github_MultiSpectral/TetraLEDarduino/Pilot_Data')
    
    save(sprintf('SubID%s_Expt%s_Freq%d_Rep%d_%s.mat',...
        dpy.SubID,dpy.ExptID,dpy.Freq,dpy.Repeat,Data.Date),'Data');
    %save figure
    savefig(sprintf('SubID%s_Expt%s_Freq%d_Rep%d_%s.fig',...
        dpy.SubID,dpy.ExptID,dpy.Freq,dpy.Repeat,Data.Date));
    fprintf('\nSubject %s data saved\n',dpy.SubID);
    fprintf('\n******** End of Condition ********\n');
    CondName=sprintf('%s',dpy.ExptID);
    allConds{thisCond}=CondName;
    FreqName=sprintf('Freq%d',dpy.Freq);
    allFreqs{thisCond}=FreqName;
    TempData.Thresh.(CondName).(FreqName)=Data.contrastThresh;
    TempData.stDevPos.(CondName).(FreqName)=Data.contrastStDevPos;
    TempData.stDevNeg.(CondName).(FreqName)=Data.contrastStDevNeg;
    
    AllData.OrderOfConditions{thisCond}=fullCondName;
      
    AllData.(CondName).(FreqName)=Data;
    
    clear Data
    close all
end
Speak('All conditions complete','Daniel');
finalDate=datestr(now,30);
save(sprintf('SubID%s_Palamedes_Opponency_Rep%d_%s.mat',...
    dpy.SubID,dpy.Repeat,finalDate),'AllData');
%turn off LEDs and close connection to ardunio
CloseArduino(s);
for thisCond=1:length(Cond)
    theCondName=allConds{thisCond};
    for thisFreq=1:length(Freq)
        theFreqName=allFreqs{thisFreq};
        fprintf('\nContrast Threshold for Cond %s  %s : %.2f   StDev +%.2f -%.2f\n',...
        theCondName,theFreqName,TempData.Thresh.(theCondName).(theFreqName),...
        TempData.stDevPos.(theCondName).(theFreqName),...
        TempData.stDevNeg.(theCondName).(theFreqName));
    end
end


timeElapsed=toc/60;
fprintf('Experiment complete in %.3f minutes\n',timeElapsed);