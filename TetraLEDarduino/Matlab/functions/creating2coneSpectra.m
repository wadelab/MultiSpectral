function [Spectra,dpy]=creating2coneSpectra(dpy)
% Spectra=creating2coneSpectra(WLrange,LMpeak)
%
% WLrange = the range of wavelengths to output e.g. 400:1:720
% LMpeak  = lambdaMax of cone in the long-medium wavelength region
% 
% Import stockman CFs and output single matrix of desired wavelengths and
% LMS spectra.
% The spectra for the 'LM' cone will be created by shifting the Lcone or
% Mcone CF, depending on whether LM peak is nearest to L or M peak
%
% written by LW 190815

%desired WL range
WL1nm=dpy.WLrange; 
LMpeak=dpy.LMpeak;
%load in the 0.1nm stockmanCFs
load('stockman01nmCF.mat');
%assign cones and WLs to variables
Lcone=stockman.Lcone;
Mcone=stockman.Mcone;
Scone=stockman.Scone;
WL=stockman.wavelength;
CombinedRaw=cat(2,WL,Lcone,Mcone,Scone);

%find row that corresponds to the LMpeak WL
LMpeakWL_indx = find(CombinedRaw == LMpeak);

%if an exact match isn't found, get to nearest by looking across a range
%+/-1 and taking a rounded up average (in case a decimal)
if isempty(LMpeakWL_indx)
    %if 1 row doesn't correspond,find nearest
    LMpeakWL_indx = find(CombinedRaw <= (LMpeak+1) & CombinedRaw >= (LMpeak-1));
    LMpeakWL_indx = round(mean(LMpeakWL_indx));
end

%Find whether the L and M cone peak is nearest to the LMpeak, by finding
%which has highest value for that WL.

[~,coneToUse]=max(CombinedRaw(LMpeakWL_indx,2:3));
if coneToUse==1
    dpy.CreatedSpectra.coneUsed='Lcone';
elseif coneToUse==2;
    dpy.CreatedSpectra.coneUsed='Mcone';
end

%find the WL peak of the coneToUse, i.e. where sensitivity is 1
coneToShiftWL_indx = find(CombinedRaw(:,coneToUse+1) == 1); %+1 because first column is wavelengths
coneToShiftWL_indx = round(mean(coneToShiftWL_indx));

%Shift the Entire column of sensitivity values so that peak is on the
%LMpeak

shiftDistance=abs(coneToShiftWL_indx-LMpeakWL_indx);
dpy.CreatedSpectra.absShiftDistance=shiftDistance;
newLM=CombinedRaw(:,coneToUse+1);

if coneToShiftWL_indx > LMpeakWL_indx
    newLM=newLM(shiftDistance+1:end,1); %remove first rows corresponding to total number needing to shift
    newLM(end+1:end+shiftDistance,1)=0; %add 0's to end rows corresponding to total number needing to shift
    finalLM=newLM;
    dpy.CreatedSpectra.ShiftDirection='ToShorterPeak';
    disp('Shift to shorter peak')
elseif coneToShiftWL_indx < LMpeakWL_indx
    newLM=cat(1,zeros(shiftDistance,1),newLM); %remove first rows corresponding to total number needing to shift
    finalLM=newLM(1:(length(newLM)-shiftDistance),:); %add 0's to end rows corresponding to total number needing to shift
    dpy.CreatedSpectra.ShiftDirection='ToLongerPeak';
    disp('Shift to longer peak')
elseif coneToShiftWL_indx == LMpeakWL_indx
    finalLM=newLM;
    dpy.CreatedSpectra.ShiftDirection='NoShiftNeeded';
    disp('No shift needed')
end

%Now resample to the desired WLrange
LMcone1nmResample=interp1(WL,finalLM,WL1nm); %l cone
Scone1nmResample=interp1(WL,Scone,WL1nm); %s cone

%save out spectra with wavelengths (WL,L,M,S)
Spectra=cat(2,WL1nm,LMcone1nmResample,Scone1nmResample);
% 
% %plot figure
% figure()
% plot(Spectra(:,1),Spectra(:,2:end))
