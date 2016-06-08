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
dpy.NumTrials=5;
% Ask the user to enter a Subject ID number
SubID=-1; 
while(SubID<1)
    SubID=input ('Enter Subject ID, e.g. 001: ','s'); %prompts to enter a subject ID
    if(isempty(SubID))
        SubID=-1;
    end
end
dpy.SubID=SubID;

dpy.NumSpec=4; 
dpy.LprimePosition=0.5;
theExptID={'LM','S'};
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

%shuffle the order of the conditions so conditions are run in random order
Cond=Shuffle(theExptID);
Freq=Shuffle(theFreq);

totalConds=length(Cond)+length(Freq);
%run a dummy trial at start of experiment

k=1; %index for total conds
% for each frequency
for thisFreq=1:length(Freq)
    dpy.Freq=Freq(thisFreq);
    
    % for each condition
    for thisCond=1:length(Cond)
        dpy.ExptID=Cond{thisCond};
        
        fullCondName=sprintf('%s_Freq%d',dpy.ExptID,dpy.Freq);
        
        % Now send experiment details out and start experiment trials.
        
        Data=Run_TetraExp_DUE_5LEDs(dpy,s);
        
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
        allFreqs{thisFreq}=FreqName;
        TempData.Thresh.(CondName).(FreqName)=Data.contrastThresh;
        TempData.stDevPos.(CondName).(FreqName)=Data.contrastStDevPos;
        TempData.stDevNeg.(CondName).(FreqName)=Data.contrastStDevNeg;
        
        AllData.OrderOfConditions{k}=fullCondName;
        k=k+1; %update index
        
        AllData.(CondName).(FreqName)=Data;
        
        clear Data
        close all
    end
end
Speak('All conditions complete','Daniel');
finalDate=datestr(now,30);
save(sprintf('SubID%s_Pilot2_Opponency_Rep%d_%s.mat',...
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