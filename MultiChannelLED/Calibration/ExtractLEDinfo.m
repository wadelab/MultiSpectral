%calculates the half-bandwidth at half height for the max output of each
%LED
%
%written by LEW 150516

%import the LED spectra
load('LEDspectra_220416.mat')

%interpolate values across wavelengths spaced in 1nm steps
curWLs=LEDspectra(:,1);
curLEDs=LEDspectra(:,2:end);
newWLs=round(min(curWLs)):.1:round(max(curWLs));
%create zero matrix for new interpolated LED spectra
newLEDs=zeros(length(newWLs),size(curLEDs,2));
for thisLED=1:size(curLEDs,2)
    newLEDs(:,thisLED)=interp1(curWLs,curLEDs(:,thisLED),newWLs);
end
%remove negatives and NaNs
    newLEDs(newLEDs<0)=0;
    newLEDs(isnan(newLEDs))=0;

%loop through each LED
for thisLED=1:size(newLEDs,2)
    curLEDname=sprintf('LED%d',thisLED);
%get the peak wavelength from max output of the LED
[maxOutput,~]=max(newLEDs(:,thisLED));
wlIndx=find(newLEDs(:,thisLED)==maxOutput);
LEDdata.(curLEDname).maxOutputVal=maxOutput;
%get the half-height of the max output
LEDdata.(curLEDname).halfOutputVal=maxOutput/2;

if length(wlIndx)==1 %if only one wavelength matches the max val save out
LEDdata.(curLEDname).peakWL=newWLs(1,wlIndx);
else %if more than one, take the average wavelength
    LEDdata.(curLEDname).peakWL=mean(newWLs(1,wlIndx));
    wlIndx=max(wlIndx);
end

% find the half-bandwidth at half-height of the max output:
% first get the wavelengths that correspond to half height (i.e. should be 
% two, one for each side of the curve (lower, upper)
indxHalfHeight=find(newLEDs(:,thisLED)>=LEDdata.(curLEDname).halfOutputVal-1 & newLEDs(:,thisLED)<=LEDdata.(curLEDname).halfOutputVal+1);
indxHalfHeightLower=indxHalfHeight;
indxHalfHeightLower(indxHalfHeight>=wlIndx)=[];
indxHalfHeightLower=mean(newWLs(indxHalfHeightLower));

indxHalfHeightUpper=indxHalfHeight;
indxHalfHeightUpper(indxHalfHeight<=wlIndx)=[];
indxHalfHeightUpper=mean(newWLs(indxHalfHeightUpper));

LEDdata.(curLEDname).wlsHalfHeight=[indxHalfHeightLower,indxHalfHeightUpper];

%Calculate the difference between the peak wavelength and each of the
%wavelengths at half-height of max output
LEDdata.(curLEDname).wlsDifference=abs(LEDdata.(curLEDname).wlsHalfHeight-LEDdata.(curLEDname).peakWL);

%take average of these two differences as the measure of half-bandwidth
LEDdata.(curLEDname).meanHalfBandwidth=mean(LEDdata.(curLEDname).wlsDifference);
%output the peak +/- half-bandwidth at half-height for each LED
fprintf('%s peak: %.2f  Half-bandwidth: %.2f\n',curLEDname,LEDdata.(curLEDname).peakWL,LEDdata.(curLEDname).meanHalfBandwidth);
end
