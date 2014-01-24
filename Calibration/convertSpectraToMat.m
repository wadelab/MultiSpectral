clear all

baseDir='C:\Users\WadeLab\Dropbox\WadelabWadeShare\LightboxStimulus\TetrachromatStim\Calibration\180713_throughDeliverySystem'
%/Users/alexwade/Dropbox/WadelabWadeShare/LightboxStimulus/TetrachromatStim/Calibration/180713_throughDeliverySystem';
chdir(baseDir);

names=dir('LED*.txt');

for thisLED=1:5
    thisLEDName=names(thisLED).name;
    newData = importdata(thisLEDName);

    % New data.data now has wavelength, amplitude in its two columns
    lowVal=max(find(newData.data(:,1)<400))
    hiVal=min(find(newData.data(:,1)>700))

    
    croppedData(:,thisLED)=newData.data(lowVal:hiVal,2);
    croppedWL(:,thisLED)=newData.data(lowVal:hiVal,1);
    figure(2);
 
    
end

desiredWL=linspace(400,700,151);
% We interpolate the input spectra to the desired output points
% using interp1
linterp=interp1(croppedWL(:,1),croppedData,desiredWL);
figure(1);
plot(linterp);

comment='Calibrated 180713 by LW using Jaz Spectrometer - through fibre optic display setup';

save('visibleLED_180713.mat','linterp','comment','croppedWL');

