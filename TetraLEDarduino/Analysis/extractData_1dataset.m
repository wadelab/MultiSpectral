%script to extract and plot data from 'testLM' data trials
clear all; close all;

addpath(genpath('/Users/lew507/Documents/York Uni PhD/GitHub_MultiSpectral'));

startpath=pwd;
theFile=uigetfile(startpath,'Select .mat file containing data');
load(theFile)

%save out the field names, sort wavelength order
sortConds=sort(fieldnames(AllData));

for thisCond=1:length(sortConds)
    currCond=sortConds{thisCond,1};
    peakNum=strsplit(sortConds{thisCond,1},'peak');
    peakNum=str2double(peakNum(1,2));
    
    
    Data(thisCond,1)=peakNum; %save out the wavelength peak used
    Data(thisCond,2)=AllData.(currCond).contrastThresh; %save out the threshold
    Data(thisCond,3)=AllData.(currCond).contrastStDevPos; %save out the stDev pos value
    Data(thisCond,4)=AllData.(currCond).contrastStDevNeg; %save out the stDev neg value
    
end

figure()
plot(Data(:,1),Data(:,2))