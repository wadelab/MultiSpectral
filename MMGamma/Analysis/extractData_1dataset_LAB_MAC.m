%script to extract and plot data 
clear all; close all;

addpath(genpath('/Users/wadelab/GitHub_MultiSpectral/TetraLEDarduino'));

startpath=pwd;
theFile=uigetfile(startpath,'Select .mat file containing data');
load(theFile)

%save out the field names, sort wavelength order
sortConds=sort(fieldnames(AllData));

for thisCond=1:length(sortConds)
    currCond=sortConds{thisCond,1};
    Pos=strsplit(sortConds{thisCond,1},'peak');
    Pos=str2double(Pos{2});
    
    
    Data(thisCond,1)=Pos; %save out the L prime position used
    Data(thisCond,2)=AllData.(currCond).contrastThresh; %save out the threshold
    Data(thisCond,3)=AllData.(currCond).contrastStDevPos; %save out the stDev pos value
    Data(thisCond,4)=AllData.(currCond).contrastStDevNeg; %save out the stDev neg value
    
end

figure()
plot(Data(:,1),Data(:,2))