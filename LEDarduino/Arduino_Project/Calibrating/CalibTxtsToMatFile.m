% Script to import all calibration data from txt files into a single .mat
% file, with the first column containing the wavelengths and subsequent
% columns containing the measurements for each LED.
% Make sure there is a logical naming system for the LED txt files, i.e.
% LED1, LED2, LED3, etc so that the output .mat file is logically
% structured in order of the LEDs
%
% written by LW on 130215
% modified from script written by SL & LW on 180713 'convertSpectraToMat'

% opens window & prompts user to select the folder containing the calibration files
baseDir=uigetdir('','Select the folder containing the calibration txt files'); 
pause(1);

%change directory to the selected folder
cd(baseDir);

%find all the '.txt' files - N.B. the folder containing the calibration
%files should ideally ONLY contain the calibration files.
names=dir('*.txt');
numLEDs=length(names); %number of LEDs/files

% for each LED
for thisLED=1:numLEDs
    thisLEDName=names(thisLED).name; % extract the file name of the current LED
    
    %create temp variable for the imported data
    tempDataFile = importdata(thisLEDName);
    
    %save out the wavelength values in the first column of the final output
    %file (it's OK that it overwrites with each loop, as these are always 
    %the same - assuming no major Jaz settings are changed within a 
    %calibration session!)
    LEDspectra(:,1)=tempDataFile.data(:,1);

    %extract the integration time used, and remove text from before and
    %after the integration time, which is given in usec
    intTime=tempDataFile.textdata(9,1);
    intTime{1}(1:25)=[];
    intTime{1}(end-10:end)=[];
    intTime=intTime{1};
    
    %convert the microseconds to milliseconds. First convert from char to
    %num 
    intTime=(str2double(intTime))/1000;
    
    %scale the spectra by the integration time so values are per ms
    %(to account for any particularly bright LEDs that required a different 
    %integration time) and save in the columns following the wavelength col
    LEDspectra(:,thisLED+1)=tempDataFile.data(:,2)/intTime;
    
end

%visualise the spectra
plot(LEDspectra(:,1),LEDspectra(:,2:end));

%save out the variable as 'LEDspectra_DD-MMM-YYYY' format - using date.
%This will open a window for you to select the folder location for the
%saved .mat file
uisave('LEDspectra',sprintf('LEDspectra_%s',date))

