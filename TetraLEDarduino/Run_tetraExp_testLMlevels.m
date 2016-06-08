% Script to specify experiment conditions and then run the experiment.
% (make sure arduino script is already running).
% 
% Edit the 'peakLevels' array to list the levels that should be tested for a
% cone peaking in the Long to middle wavelength region, i.e. enter a list
% of lambdaMax values
% e.g.
% peakLevels = [540,545,555,560,570,575];
%
% Specify dpy structure to send to the Run_TetraExp_DUE_5LEDs script.
% dpy should contain:
% dpy.SubID     = the SubjectID 
% dpy.NumSpec   = the number of cone spectra to use, either 2 3 or 4
% dpy.ExptID    = the experiment ID
% dpy.Repeat    = which session number is it
% dpy.Freq      = the frequency (Hz) of the stimulus  
%
%
% written by LEW 20/08/15

clear all; close all;
addpath(genpath('/Users/wadelab/Github_MultiSpectral/TetraLEDarduino'))

%connect to arduino
s=ConnectToArduino;

%set the peak levels here:
peakLevels=[540,555,570];
%peakLevels=[585,580,575,570,565,560,555,550,545,540,535,530];

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
dpy.SubID=str2double(SubID);

dpy.NumSpec=2;
dpy.ExptID='TESTLM';
dpy.Freq=2;

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
peakLevels=Shuffle(peakLevels);
for thisPeak=1:length(peakLevels)
    dpy.LMpeak=peakLevels(thisPeak);
 

% Now send experiment details out and start experiment trials.

Data=Run_TetraExp_DUE_5LEDs(dpy,s);

%save out a file containing the contrastThresh, SubID, experimentType, freq and
%Session num

%go to wherever you want to save it
cd('/Users/wadelab/Github_MultiSpectral/TetraLEDarduino/Data_tetraStim')

save(sprintf('SubID%d_Cond%s_peak%d_Freq%.1f_Rep%d_%s.mat',...
    dpy.SubID,dpy.ExptID,dpy.LMpeak,dpy.Freq,dpy.Repeat,Data.Date),'Data');
%save figure
savefig(sprintf('SubID%s_numSpec%d_Cond%s_Freq%.1f_Rep%d_%s.fig',...
    dpy.SubID,dpy.NumSpec,dpy.ExptID,dpy.Freq,dpy.Repeat,Data.Date));
fprintf('\nSubject %d data saved\n',dpy.SubID);
fprintf('\n******** End of Experiment ********\n');
system ('say All trials complete for this condition');
peakname=sprintf('peak%d',peakLevels(thisPeak));
allPeaks{thisPeak}=peakname;
TempData.Thresh.(peakname)=Data.contrastThresh;
TempData.stDevPos.(peakname)=Data.contrastStDevPos;
TempData.stDevNeg.(peakname)=Data.contrastStDevNeg;


AllData.(peakname)=Data;
end
system ('say All conditions complete');
save(sprintf('SubID%d_Cond%s_multipleLevels_Freq%.1f_Rep%d_%s.mat',...
    dpy.SubID,dpy.ExptID,dpy.Freq,dpy.Repeat,Data.Date),'AllData');
%turn off LEDs and close connection to ardunio
CloseArduino(s);
for thisPeak=1:size(peakLevels,2)
    thename=allPeaks{thisPeak};
    fprintf('\nContrast Threshold for peak %d: %.3f   StDev +%.3f -%.3f\n',...
        peakLevels(thisPeak),TempData.Thresh.(thename),TempData.stDevPos.(thename),...
        TempData.stDevNeg.(thename));
end


timeElapsed=toc/60;
fprintf('Experiment complete in %.3f minutes\n',timeElapsed);