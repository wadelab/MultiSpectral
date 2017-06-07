% Script to load in calibration .txt files for each LED, and convert all
% values into intensity per ms (different intentisies of LEDs required a
% slight variance in the integration time used for the calibration).
%
% written by LEW on 220115


% Open pop-up window to select the folder with the relevant files
startpath=pwd; %set present working directory
directory=uigetdir(startpath,'Select folder containing the calibration files');

cd ((directory));
TXTfiles=dir('*.txt'); %save out just txt files

%pre-allocate the final variable with the correct number of columns (plus1
%for the wavelength values)
thisSize=size(TXTfiles,1)+1; %number of columns needed
LEDspectraScaled(:,1:thisSize)=zeros; %create single row with correct num columns

%this loop goes through each text file and imports the data and the
%integration time used, then converts the intensity values to per ms

for thisLED=1:size(TXTfiles,1)
    theFile=dir(sprintf('LED%d*',thisLED));
    for theFileType=1:size(theFile,1);
        a=strcmp('txt',theFile(theFileType).name(end-2:end));
        if a==0
            continue
        elseif a==1
            fileName=theFile(theFileType).name;
        end
    end
    %N.B. at the moment this relies on logical LED naming, i.e. LED1, LED2 etc
    LED=sprintf('%s%d','LED',thisLED); %create string for saving out name
    Calibration.(LED)=importdata((fileName));
    
    %we know that information on the integration time is in cell 9 of the
    %text data (in the imported data).  Save out the contents of this
    %string and remove the characters surrounding the integration number
    %(in usec)
	tempTextCell=Calibration.(LED).textdata{9,1};
    tempTextCell(end-10:end)=[]; %clear last 11 characters
    tempTextCell(1:25)=[]; %clear first 25 characters
    
    %convert string into a number (value in usec)
    tempInteg=str2double(tempTextCell);
    %Save out integration - divide by 1000 to convert to ms
    Calibration.(LED).IntegrationInMS=tempInteg/1000;
    
    %Save out the LED calibrations that have been scaled by the integration
    %time (i.e. divided by the integration time in ms) - start from column
    %2 so that the first column can contain the wavelength values
    
    
    %check whether the final LEDspectraScaled variable has been
    %modified with correct number of rows yet. If it still only has 1 row 
    %then create matrix of zeros with the correct row number (gathered from
    %total rows of data) and fill in the calibration data. When this has
    %been done once it'll skip to just filling in data in the relevant
    %column position
    if size(LEDspectraScaled,1)==1;
        LEDspectraScaled(1:length(Calibration.(LED).data),1:thisSize)=zeros; %pre-allocated to correct row length
        LEDspectraScaled(:,thisLED+1)=Calibration.(LED).data(:,2)./Calibration.(LED).IntegrationInMS;
    else
        LEDspectraScaled(:,thisLED+1)=Calibration.(LED).data(:,2)./Calibration.(LED).IntegrationInMS;
    end
      
end
%use final LED spectra processed to save out the wavelengths values to the
%first column (wavelengths are a fixed range in the calibration)
LEDspectraScaled(:,1)=Calibration.(LED).data(:,1); 
LEDspectra=LEDspectraScaled;

%save out the work space of 'LEDspectraScaled' to be loaded into to any
%relevant script