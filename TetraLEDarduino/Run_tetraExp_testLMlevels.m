% Script to specify experiment conditions and then run the experiment.
% (make sure arduino script is already running).
% Specify dpy structure to send to the Run_TetraExp_DUE_5LEDs script.
%
% dpy should contain:
% dpy.SubID     = the SubjectID 
% dpy.NumSpec   = the number of cone spectra to use, either 2 3 or 4
% dpy.ExptID    = the experiment ID
% dpy.Repeat    = which session number is it
% dpy.Freq      = the frequency (Hz) of the stimulus  
%
% TODO - add details of experiment options available
%
% written by LEW 20/08/15

clear all; close all;
addpath(genpath('/Users/wadelab/Github_MultiSpectral/TetraLEDarduino'))

%connect to arduino
s=ConnectToArduino;


% Prompt for details

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



peakLevels=[580,570,560,550,540];
peakLevels=shuffle(peakLevels);
for thisPeak=1:length(peakLevels)
    dpy.LMpeak=peakLevels(thisPeak);
 

% Now send experiment details out and start experiment trials.

Data=Run_TetraExp_DUE_5LEDs(dpy,s);

%save out a file containing the contrastThresh, SubID, experimentType, freq and
%Session num

%go to wherever you want to save it
cd('/Users/wadelab/Github_MultiSpectral/TetraLEDarduino/Data_tetraStim')

save(sprintf('SubID%d_numSpec%d_Cond%s_Freq%.1f_Rep%d_%s.mat',...
    dpy.SubID,dpy.NumSpec,dpy.ExptID,dpy.Freq,dpy.Repeat,Data.Date),'Data');

%save figure
savefig(sprintf('SubID%s_Cond%s_Freq%.1f_Rep%d_%s.fig',...
    SubID,thisExp,modulationRateHz,Repeat,Date));
fprintf('\nSubject %s data saved\n',SubID);
fprintf('\n******** End of Experiment ********\n');
system ('say All trials complete for this condition');
TempDataThresh.(thisPeak)=Data.contrastThresh;

end
system ('say All conditions complete')

%turn off LEDs and close connection to ardunio
CloseArduino(s)
for thisPeak=1:size(peakLevels,2)
    fprintf('\nContrast Threshold for %d:  %.3f\n',peakLevels{thisPeak},TempDataThresh.(peakLevels{thisPeak}));
end