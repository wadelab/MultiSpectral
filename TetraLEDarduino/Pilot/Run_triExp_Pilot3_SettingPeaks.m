% Script to specify experiment conditions and then run the experiment.
% (make sure arduino script is already running).
% 
% Runs Lum (LMS), L-M, and S-cone isolating conditions and different
% frequencies to check thresholds are as expected (i.e. that the stimulus
% is properly isolating the different channels).
%
% Specify dpy structure to send to the Run_TetraExp_DUE_5LEDs script.
% dpy should contain:
% dpy.SubID          = the SubjectID 
% dpy.NumSpec        = the number of cone spectra to use, either 2 3 or 4
% dpy.ExptID         = the experiment ID
% dpy.Repeat         = which session number is it
% dpy.Freq           = the frequency (Hz) of the stimulus  
%
% written by LEW 20/08/15

clear all; close all;
addpath(genpath('/Users/wade/Documents/GitHub_Multispectral/TetraLEDarduino'))

%connect to arduino
s=ConnectToArduino;

% set number of trials in staircase
dpy.NumTrials=30;
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
dpy.ConeTypes='LpMS';
dpy.ExptID='L';
dpy.Freq=2; %the frequencies to test for each condition
FreqName=sprintf('Freq%d',dpy.Freq);
% set range of Lpeaks to try (where L mid is ~570 and M mid is ~542)
thePeaks=[562,565,568,571,574];
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
Peak=Shuffle(thePeaks);

totalConds=length(Peak);
%run a dummy trial at start of experiment
dummyTrial(s)

k=1; %index for total conds
    % for each condition
for thisPeak=1:length(Peak)
    if dpy.ExptID=='L'
        dpy.Lpeak=Peak(thisPeak);
        fullCondName=sprintf('%s_Freq%d_Peak%.1f',dpy.ExptID,dpy.Freq,dpy.Lpeak);

    elseif dpy.ExptID=='M'
        dpy.Mpeak=Peak(thisPeak);
        fullCondName=sprintf('%s_Freq%d_Peak%.1f',dpy.ExptID,dpy.Freq,dpy.Mpeak);
    end
        % Now send experiment details out and start experiment trials.
        
        Data=Run_TetraExp_DUE_5LEDs(dpy,s);
        
        %save out a file containing the contrastThresh, SubID, experimentType, freq and
        %Session num
        
        %go to wherever you want to save it
        cd('/Users/wade/Documents/Github_MultiSpectral/TetraLEDarduino/Pilot_Data')
        
        save(sprintf('SubID%s_Expt%s_Freq%d__Peak%.1f_Rep%d_%s.mat',...
            dpy.SubID,dpy.ExptID,dpy.Freq,Peak(thisPeak),dpy.Repeat,Data.Date),'Data');
        %save figure
        savefig(sprintf('SubID%s_Expt%s_Freq%d_Peak%.1f_Rep%d_%s.fig',...
            dpy.SubID,dpy.ExptID,dpy.Freq,Peak(thisPeak),dpy.Repeat,Data.Date));
        fprintf('\nSubject %s data saved\n',dpy.SubID);
        fprintf('\n******** End of Condition ********\n');
        CondName=sprintf('%s%d',dpy.ExptID,(round(Peak(thisPeak))));
        allConds{thisPeak}=CondName;
        
        
        TempData.names.(CondName)=CondName;
        TempData.Thresh.(CondName)=Data.contrastThresh;
        TempData.stDevPos.(CondName)=Data.contrastStDevPos;
        TempData.stDevNeg.(CondName)=Data.contrastStDevNeg;
        
        AllData.OrderOfConditions{k}=fullCondName;
        k=k+1; %update index
        
        AllData.(CondName).(FreqName)=Data;
        
        clear Data
        close all
    end
Speak('All conditions complete','Daniel');
finalDate=datestr(now,30);
save(sprintf('SubID%s_Pilot3_SettingPeaks_Rep%d_%s.mat',...
    dpy.SubID,dpy.Repeat,finalDate),'AllData');
%turn off LEDs and close connection to ardunio
CloseArduino(s);
    for thisPeak=1:length(Peak)
        currentCond=allConds{thisPeak};
        fprintf('\nContrast Threshold for Cond %s  Peak %.1f  : %.2f   StDev Pos %.2f Neg %.2f\n',...
        dpy.ExptID,Peak(thisPeak),TempData.Thresh.(currentCond),...
        TempData.stDevPos.(currentCond),...
        TempData.stDevNeg.(currentCond));
    end



timeElapsed=toc/60;
fprintf('Experiment complete in %.3f minutes\n',timeElapsed);