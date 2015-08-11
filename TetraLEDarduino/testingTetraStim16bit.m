addpath(genpath('/Users/wadelab/Github_MultiSpectral'))
CONNECT_TO_ARDUINO = 1; % For testing on any computer
BITDEPTH=12;
if(~isempty(instrfind))
   fclose(instrfind);
end

if (CONNECT_TO_ARDUINO)  

    s=serial('/dev/tty.usbmodem5d11');%,'BaudRate',9600);q
    fopen(s);
    disp('*** Connecting to Arduino');
    
else
    s=0;
end

%InitializePsychSound; % Initialize the Psychtoolbox sounds
pause(2);
fprintf('\n****** Experiment Running ******\n \n');
LEDamps=int16([0,0,0,0,0]);
LEDbaseLevel=int16(([.5,.5,.5,.5,.5])*(2^BITDEPTH)); % Adjust these to get a nice white background....THis is convenient and makes sure that everything is off by default
nLEDsTotal=length(LEDamps);


SubID=999;
experimentTypeS='L';
experimentType=-1; % Ask t*********************
modulationRateHz=2;
Repeat=1;

LEDsToUse=find(LEDbaseLevel);% Which LEDs we want to be active in this expt?
nLEDs=length(LEDsToUse);
% Iinitialize the display system
% Load LEDspectra calib contains 1 column with wavelengths, then the LED calibs
load('LEDspectra_070515.mat'); %load in calib for the prizmatix
LEDcalib=LEDspectra; %if update the file loaded, the name only has to be updated here for use in rest of code
LEDcalib(LEDcalib<0)=0;
clear LEDspectra
%resample to specified wavelength range (LEDspectra will now only contain
%the LED calibs, without the column for wavelengths)
dpy.WLrange=(400:1:720)'; %using range from 400 min to 720+
dpy.bitDepth=BITDEPTH;

spectrumIndex=0;
for thisLED=LEDsToUse
    spectrumIndex=spectrumIndex+1;
    LEDspectra(:,thisLED)=interp1(LEDcalib(:,1),LEDcalib(:,1+thisLED),dpy.WLrange);
end
LEDspectra(LEDspectra<0)=0;

%LEDspectra=LEDspectra-repmat(min(LEDspectra),size(LEDspectra,1),1);
%sumLED=sum(LEDspectra);
maxLED=max(LEDspectra);
LEDscale=1./maxLED;
%LEDscale=[128 128 128 128 128];


% ********** this isn't currently used anywhere else... should it be?!
actualLEDScale=LEDscale./max(LEDscale);


dpy.LEDspectra=LEDspectra(:,LEDsToUse); %specify which LEDs to use
dpy.LEDsToUse=LEDsToUse;
%dpy.bitDepth=8; % Can be 12 on new arduinos
%dpy.backLED.dir=double(LEDbaseLevel(LEDsToUse))./max(double(LEDbaseLevel(LEDsToUse)))
dpy.backLED.dir=double(LEDbaseLevel)/double(max(LEDbaseLevel));

dpy.backLED.scale=.5;
dpy.LEDbaseLevel=round(dpy.backLED.dir*dpy.backLED.scale*(2.^dpy.bitDepth-1)); % Set just the LEDs we're using to be on a 50%
dpy.nLEDsTotal=nLEDsTotal;
dpy.nLEDsToUse=length(dpy.LEDsToUse);
dpy.modulationRateHz=modulationRateHz;





dummyStim.stimLMS.dir=[1 1 1 1];
dummyStim.stimLMS.scale=.1;
dummyResponse=tetra_led_doLEDTrial_5LEDs(dpy,dummyStim,q,s,1); % This should return 0 for an incorrect answer and 1 for correct
pause(1)


disp('L-M at 2%');
stim.stimLMS.dir=[0.5 0 -1 0]; % L cone isolating
stim.stimLMS.scale= .02;
        
response=tetra_led_doLEDTrial_5LEDs(dpy,stim,q,s); % This should return 0 for an incorrect answer and 1 for correct

    dummyStim.stimLMS.dir=[1 1 1 1];
dummyStim.stimLMS.scale=.1;
dummyResponse=tetra_led_doLEDTrial_5LEDs(dpy,dummyStim,q,s,1); % This should return 0 for an incorrect answer and 1 for correct
pause(1)
    

if (isobject(s)) % This is shorthand for ' if s>0 '
    % Shut down arduino to save the LEDs
      fwrite(s,zeros(5,1),'uint16');
      fwrite(s,zeros(5,1),'uint16');
      fwrite(s,zeros(1,1),'uint16');
      disp('Turning off LEDs');
      pause(1)
      fclose(s);
end
