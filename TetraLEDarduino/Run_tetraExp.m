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

% Ask the user to specify which type of experiment they are running - i.e.
% how many cone spectra are needed
numSpectra=-1; 
while(numSpectra<1)
    numSpectra=input ('Number of cone spectra needed e.g. 2,3,4: ','s'); %
    if(isempty(numSpectra))
        numSpectra=-1;
    end
end
dpy.NumSpec=str2double(numSpectra);

% Ask the user to enter a valid experiment type probing a particuar direction in LMS space
experimentType=-1; 
while(experimentType<1)
    experimentType=input ('Experiment condition code (L, Lp, M, S, LMS, LM, testLM): ','s'); %
    experimentType=upper(experimentType); %make all uppercase
    if(isempty(experimentType))
        experimentType=-1;
    end
end
dpy.ExptID=experimentType;

if strcmp(dpy.ExptID,'TESTLM')
   LMpeak=input ('Enter wavelength peak of the testLM e.g. 565: ','s'); %
   LMpeak=str2num(LMpeak);
   dpy.LMpeak=LMpeak;
end
    

% Ask the user to enter the modulation rate (in Hz)
modulationRateHz=-1; 
while((modulationRateHz<0) || (modulationRateHz>65))
    modulationRateHzString=input ('Frequency in Hz e.g. 0.5, 1, 2, 4, etc: ','s'); %enter the Hz for exp
    modulationRateHz=str2num(modulationRateHzString);
    if(isempty(modulationRateHz))
        modulationRateHz=-1;
    end
end
dpy.Freq=modulationRateHz;

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

%open connection to arduino
s=ConnectToArduino;
% Now send experiment details out and start experiment trials.

Data=Run_TetraExp_DUE_5LEDs(dpy,s);

%save out a file containing the contrastThresh, SubID, experimentType, freq and
%Session num

%go to wherever you want to save it
cd('/Users/wadelab/Github_MultiSpectral/TetraLEDarduino/Data_tetraStim')

save(sprintf('SubID%d_numSpec%d_Cond%s_Freq%.1f_Rep%d_%s.mat',...
    dpy.SubID,dpy.NumSpec,dpy.ExptID,dpy.Freq,dpy.Repeat,Data.Date),'Data');

%save figure
savefig(sprintf('SubID%s_numSpec%d_Cond%s_Freq%.1f_Rep%d_%s.fig',...
    dpy.SubID,dpy.NumSpec,dpy.ExptID,dpy.Freq,dpy.Repeat,Data.Date));
fprintf('\nSubject %d data saved\n',dpy.SubID);
fprintf('\n******** End of Experiment ********\n');
system('say All trials complete');
%turn off LEDs and close ardunio
CloseArduino(s);
