%script to extract and plot data 
clear all; close all;

addpath(genpath('/Users/lew507/Documents/York Uni PhD/GitHub_MultiSpectral'));

startpath=pwd;
theFile=uigetfile(startpath,'Select .mat file containing data','MultiSelect','on');

if ischar(theFile)==1
    %just one file
    numFiles=1;
elseif ischar(theFile)==0
    numFiles=size(theFile,2);
end

for thisFile=1:numFiles;
    repeat=sprintf('Repeat%d',thisFile);
    if numFiles==1
        load(theFile)
    else
        load(theFile{thisFile})
    end

    %save out the field names, sort wavelength order
    sortConds=sort(fieldnames(AllData));

    for thisCond=1:length(sortConds)
        currCond=sortConds{thisCond,1};
        LprimePos=strsplit(sortConds{thisCond,1},'peak');
        LprimePos=str2double(LprimePos{2});


        Data(thisCond,1)=LprimePos; %save out the L prime position used
        Data(thisCond,2)=AllData.(currCond).contrastThresh; %save out the threshold
        Data(thisCond,3)=AllData.(currCond).contrastStDevPos; %save out the stDev pos value
        Data(thisCond,4)=AllData.(currCond).contrastStDevNeg; %save out the stDev neg value

    end
    CombinedData.thresholds(:,thisFile)=Data(:,2);

    figure(thisFile)
    plot(Data(:,1),Data(:,2))
end
CombinedData.AverageThresh=mean(CombinedData.thresholds,2);
CombinedData.stdevThresh=std(CombinedData.thresholds,[],2);
figure()
plot(Data(:,1),CombinedData.AverageThresh)
