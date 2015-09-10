% Script to specify experiment conditions and then run the experiment.
% (make sure arduino script is already running).
% 
% Edit the 'LMpeaks' array to list the levels that should be tested for a
% cone peaking in the Long to middle wavelength region,
% e.g.
% peakLevels = [540,550,560,570];
%
% Specify dpy structure to send to the Run_TetraExp_DUE_5LEDs script.
% dpy should contain:
% dpy.SubID          = the SubjectID 
% dpy.NumSpec        = the number of cone spectra to use, either 2 3 or 4
% dpy.ExptID         = the experiment ID
% dpy.Repeat         = which session number is it
% dpy.Freq           = the frequency (Hz) of the stimulus  
% dpy.LprimePosition = the position (0-1) between L and M cone peaks for
%                      Lprime
%
% written by LEW 20/08/15

clear all; close all;
addpath(genpath('/Users/wadelab/Github_MultiSpectral/TetraLEDarduino'))

%connect to arduino
s=ConnectToArduino;

% set number of trials in staircase
dpy.NumTrials=40;
% Ask the user to enter a Subject ID number
SubID=-1; 
while(SubID<1)
    SubID=input ('Enter Subject ID, e.g. 001: ','s'); %prompts to enter a subject ID
    if(isempty(SubID))
        SubID=-1;
    end
end
dpy.SubID=SubID;

dpy.NumSpec=2;
dpy.ExptID='TESTLM';
dpy.ExptLabel='LMCone';
dpy.Freq=2;
dpy.LprimePosition=0.5;

%peakPositions=[545.575,551.025,556.475,561.925,567.375]; %the levels of Lprime to test
peakPositions=[542.85,549.66,556.48,563.29,570.10];


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

%shuffle the order of the peaklevels so conditions are run in random order
Peaks=Shuffle(peakPositions);
for thisPeak=1:length(Peaks)
    dpy.LMpeak=Peaks(thisPeak);
 
    

% Now send experiment details out and start experiment trials.

Data=Run_TetraExp_DUE_5LEDs(dpy,s);

%save out a file containing the contrastThresh, SubID, experimentType, freq and
%Session num

%go to wherever you want to save it
cd('/Users/wadelab/Github_MultiSpectral/TetraLEDarduino/Pilot_Data')

save(sprintf('SubID%s_Expt%s_Peak%.3f_Freq%.1f_Rep%d_%s.mat',...
    dpy.SubID,dpy.ExptLabel,dpy.LMpeak,dpy.Freq,dpy.Repeat,Data.Date),'Data');
%save figure
savefig(sprintf('SubID%s_Expt%s_Peak%.2f_Freq%.1f_Rep%d_%s.fig',...
    dpy.SubID,dpy.ExptLabel,dpy.LMpeak,dpy.Freq,dpy.Repeat,Data.Date));
fprintf('\nSubject %s data saved\n',dpy.SubID);
fprintf('\n******** End of Experiment ********\n');
system ('say Condition complete');
peakname=sprintf('peak%d',round(Peaks(thisPeak)));
allPeaks{thisPeak}=peakname;
TempData.Thresh.(peakname)=Data.contrastThresh;
TempData.stDevPos.(peakname)=Data.contrastStDevPos;
TempData.stDevNeg.(peakname)=Data.contrastStDevNeg;



AllData.(peakname)=Data;

clear Data
close all
end
system ('say All conditions complete');
finalDate=datestr(now,30);
save(sprintf('SubID%s_%s_AllConditionsLMcone_Freq%.1f_%s.mat',...
    dpy.SubID,dpy.ExptLabel,dpy.Freq,finalDate),'AllData');
%turn off LEDs and close connection to ardunio
CloseArduino(s);
for thisPeak=1:size(Peaks,2)
    thename=allPeaks{thisPeak};
    fprintf('\nContrast Threshold for LMpeak %.2f: %.3f   StDev +%.3f -%.3f\n',...
        Peaks(thisPeak),TempData.Thresh.(thename),TempData.stDevPos.(thename),...
        TempData.stDevNeg.(thename));
end


timeElapsed=toc/60;
fprintf('Experiment complete in %.3f minutes\n',timeElapsed);